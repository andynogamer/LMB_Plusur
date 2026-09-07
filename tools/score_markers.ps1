<#
.SYNOPSIS
    Scores every reference image in assets/markers/ with ARCore's arcoreimg tool.

.DESCRIPTION
    Constitution D-13 requires every AR marker to score >= 75 on
    `arcoreimg eval-img` before it can be used as a tracking target. See
    docs/ar-marker-guide.md.

    Exit codes: 0 = every marker passes, 1 = at least one scored below
    MinScore, 2 = arcoreimg or the markers directory is missing. So this
    doubles as a pre-merge check.

    Runs on Windows PowerShell 5.1 and PowerShell 7+.

.PARAMETER ArcoreImg
    Path to arcoreimg.exe. Defaults to $env:ARCOREIMG, then to whatever is
    on PATH. The binary ships with the ARCore Android SDK at
    tools/arcoreimg/windows/arcoreimg.exe.

.PARAMETER MinScore
    Minimum acceptable score. Do not lower this without a constitution amendment.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools/score_markers.ps1

.EXAMPLE
    ./tools/score_markers.ps1 -ArcoreImg C:\arcore-sdk\tools\arcoreimg\windows\arcoreimg.exe
#>
[CmdletBinding()]
param(
    [string] $ArcoreImg = $(if ($env:ARCOREIMG) { $env:ARCOREIMG } else { 'arcoreimg.exe' }),
    [int]    $MinScore = 75,
    [string] $MarkersDir = 'assets/markers'
)

$ErrorActionPreference = 'Stop'

# Exit codes: 0 = all pass, 1 = a marker scored too low, 2 = tooling problem.
# Write-Host rather than Write-Error, so $ErrorActionPreference = 'Stop' does not
# throw before we can return the specific code.
if (-not (Get-Command $ArcoreImg -ErrorAction SilentlyContinue)) {
    Write-Host "arcoreimg not found: '$ArcoreImg'" -ForegroundColor Red
    Write-Host ''
    Write-Host 'Download the ARCore SDK for Android and point at the binary:'
    Write-Host '  https://github.com/google-ar/arcore-android-sdk'
    Write-Host '  tools/arcoreimg/windows/arcoreimg.exe'
    Write-Host ''
    Write-Host 'Then add that folder to PATH, set $env:ARCOREIMG, or pass -ArcoreImg.'
    exit 2
}

if (-not (Test-Path $MarkersDir)) {
    Write-Host "Markers directory not found: $MarkersDir" -ForegroundColor Red
    exit 2
}

# Note: -Include only filters when the path ends in a wildcard (or with -Recurse).
$markers = Get-ChildItem -Path (Join-Path $MarkersDir '*') -File -Include *.png, *.jpg, *.jpeg
if (-not $markers) {
    Write-Warning "No reference images found in $MarkersDir"
    exit 0
}

Write-Host ''
Write-Host "arcoreimg eval-img  |  threshold >= $MinScore" -ForegroundColor Cyan
Write-Host ('-' * 64)

$failures = @()

# arcoreimg reports "Failed to get enough keypoints" on stderr. Under
# ErrorActionPreference = 'Stop' that native stderr aborts the whole loop, so
# relax it here and judge each result ourselves.
$ErrorActionPreference = 'Continue'

foreach ($marker in $markers) {
    $raw = (& $ArcoreImg eval-img --input_image_path="$($marker.FullName)" 2>&1 |
            ForEach-Object { $_.ToString() }) -join ' '

    if ($raw -match 'Failed to get enough keypoints') {
        # Worse than a low score: the image is too flat to key on at all.
        Write-Host ("{0,-44} {1,6}  {2}" -f $marker.Name, 0, 'FAIL (no keypoints)') -ForegroundColor Red
        $failures += $marker.Name
        continue
    }

    $match = [regex]::Match($raw, '(\d+(?:\.\d+)?)')

    if (-not $match.Success) {
        Write-Host ("{0,-44} {1}" -f $marker.Name, 'NO SCORE') -ForegroundColor Red
        Write-Host ("    arcoreimg said: {0}" -f $raw)
        $failures += $marker.Name
        continue
    }

    $score = [double] $match.Groups[1].Value
    $passed = $score -ge $MinScore
    $colour = if ($passed) { 'Green' } else { 'Red' }
    $label = if ($passed) { 'PASS' } else { 'FAIL' }

    Write-Host ("{0,-44} {1,6:N0}  {2}" -f $marker.Name, $score, $label) -ForegroundColor $colour

    if (-not $passed) { $failures += $marker.Name }
}

Write-Host ('-' * 64)

if ($failures.Count -gt 0) {
    Write-Host ''
    Write-Host "$($failures.Count) of $($markers.Count) below $MinScore." -ForegroundColor Red
    Write-Host 'Try tools/normalize_markers.ps1 first (D-21) - it fixed 4 logos.' -ForegroundColor Yellow
    Write-Host 'If still failing, the art is too flat: use a marker card instead.'
    Write-Host 'Never compensate in code. See docs/ar-marker-guide.md.'
    exit 1
}

Write-Host ''
Write-Host 'All markers pass. Record the scores in docs/ar-marker-guide.md section 7.' -ForegroundColor Green
exit 0
