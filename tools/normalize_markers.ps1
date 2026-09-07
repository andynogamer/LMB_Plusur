<#
.SYNOPSIS
    Normalizes club logos into ARCore-friendly reference images.

.DESCRIPTION
    Constitution D-21. Measured on 2026-09-07, this single step moved the LMB
    logo set from 2 usable tracking targets to 4:

        bravos_leon      failed -> 90
        piratas_campeche     35 -> 100
        olmecas_tabasco      50 -> 100
        leones_yucatan       90 -> 100

    Two things were wrong with the raw assets:
      1. 9 of 10 logos were BELOW ARCore's 300x300 minimum (mostly 256x256).
      2. Four were 8-bit indexed PNGs whose transparency was being flattened
         to black, erasing the keypoints ARCore needs.

    So: flatten any alpha onto WHITE, upscale the short side to at least
    -MinShortSide, and write 24bpp PNG.

    IMPORTANT: re-encoding can also LOWER a score - tigres_quintana_roo went
    75 -> 50, because resampling softened the high-frequency detail that was
    earning its keypoints. Always re-score after normalizing and keep whichever
    version scores higher. Never assume this script is an improvement.

.PARAMETER Source
    Directory of raw logos, searched recursively. Output is named after each
    file's PARENT FOLDER, which matches the assets/images/team-logos/<club>/
    layout.

.PARAMETER Destination
    Where to write normalized PNGs.

.PARAMETER MinShortSide
    Minimum length of the shorter edge. 512 clears ARCore's 300 px floor with
    headroom. Images already larger are never downscaled.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools/normalize_markers.ps1
    powershell -ExecutionPolicy Bypass -File tools/score_markers.ps1 -MarkersDir build/markers-normalized
#>
[CmdletBinding()]
param(
    [string] $Source = 'assets/images/team-logos',
    [string] $Destination = 'build/markers-normalized',
    [int]    $MinShortSide = 512
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $Source)) {
    Write-Host "Source directory not found: $Source" -ForegroundColor Red
    exit 2
}

New-Item -ItemType Directory -Force -Path $Destination | Out-Null

$logos = Get-ChildItem -Path $Source -Recurse -File -Include *.png, *.jpg, *.jpeg
if (-not $logos) {
    Write-Host "No images found under $Source" -ForegroundColor Yellow
    exit 0
}

Write-Host ''
Write-Host "Normalizing to 24bpp PNG, short side >= $MinShortSide, alpha over white" -ForegroundColor Cyan
Write-Host ('-' * 72)

foreach ($logo in $logos) {
    $src = [System.Drawing.Image]::FromFile($logo.FullName)
    try {
        $scale = $MinShortSide / [double][Math]::Min($src.Width, $src.Height)
        if ($scale -lt 1) { $scale = 1 }   # never downscale
        $w = [int][Math]::Round($src.Width * $scale)
        $h = [int][Math]::Round($src.Height * $scale)

        $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        try {
            # White, not black: black-flattened alpha is what erased the
            # keypoints on the 8bpp indexed logos.
            $g.Clear([System.Drawing.Color]::White)
            $g.InterpolationMode = 'HighQualityBicubic'
            $g.DrawImage($src, 0, 0, $w, $h)

            $dest = Join-Path $Destination ($logo.Directory.Name + '.png')
            $bmp.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)

            "{0,-28} {1,4}x{2,-4} {3,-18} -> {4}x{5}" -f `
                $logo.Directory.Name, $src.Width, $src.Height, $src.PixelFormat, $w, $h
        }
        finally { $g.Dispose(); $bmp.Dispose() }
    }
    finally { $src.Dispose() }
}

Write-Host ('-' * 72)
Write-Host ''
Write-Host "Wrote $($logos.Count) normalized images to $Destination" -ForegroundColor Green
Write-Host 'Now re-score them and compare against the raw scores:' -ForegroundColor Yellow
Write-Host "  powershell -ExecutionPolicy Bypass -File tools/score_markers.ps1 -MarkersDir $Destination"
Write-Host 'Keep whichever version of each logo scores higher (see D-21).'
