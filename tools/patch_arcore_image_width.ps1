# Applies the AR-05 physical-width patch to pinned ar_flutter_plugin_plus 1.1.3.
#
# The plugin hardcodes AugmentedImageDatabase.addImage(..., 0.2f) and ignores
# Dart. Without this, ARCore never sees anchoMetros. Re-run after flutter pub get
# (pub may restore the unpatched plugin). Idempotent.
#
# Rollback: flutter pub cache repair, or delete the plugin folder and pub get.
# Do not bump the pin to avoid this. D-12 is exact 1.1.3.

$ErrorActionPreference = "Stop"

$pubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else {
  Join-Path $env:LOCALAPPDATA "Pub\Cache"
}
$plugin = Join-Path $pubCache "hosted\pub.dev\ar_flutter_plugin_plus-1.1.3\android\src\main\kotlin\tech\graaf\franz\ar_flutter_plugin_plus\AndroidARView.kt"

if (-not (Test-Path $plugin)) {
  Write-Error "Plugin source not found: $plugin. Run flutter pub get first."
}

$text = [System.IO.File]::ReadAllText($plugin)
if ($text.Contains("lmb-plusur: physical width")) {
  Write-Output "already patched: $plugin"
  exit 0
}

$nl = "`r`n"
if (-not $text.Contains("`r`n")) { $nl = "`n" }

function Elv { return "?" + ":" }

$fieldNeedle = "    private var imageTrackingUpdateIntervalMs: Long = 100"
$field = $fieldNeedle + $nl +
  "    // lmb-plusur: physical width - anchoMetros keyed by Flutter asset path" + $nl +
  "    private var imageWidthsMeters: Map<String, Float> = emptyMap()"
if (-not $text.Contains($fieldNeedle)) {
  Write-Error "Field anchor missing in AndroidARView.kt - plugin layout changed."
}
$text = $text.Replace($fieldNeedle, $field)

$handlerNeedle = '                        "getAnchorPose" -> {'
$handler = @(
  '                        "setImageWidths" -> {'
  '                            // lmb-plusur: physical width. Dart sends anchoMetros'
  '                            // before precompile so addImage is not stuck at 0.2f.'
  '                            val raw = call.argument<Map<*, *>>("widthsByPath")'
  '                            val parsed = mutableMapOf<String, Float>()'
  '                            if (raw != null) {'
  '                                for ((key, value) in raw) {'
  '                                    val path = key?.toString() ?: continue'
  ('                                    val meters = (value as? Number)?.toFloat() ' + (Elv) + ' continue')
  '                                    if (meters > 0f) parsed[path] = meters'
  '                                }'
  '                            }'
  '                            imageWidthsMeters = parsed'
  '                            result.success(parsed.isNotEmpty())'
  '                        }'
  $handlerNeedle
) -join $nl
if (-not $text.Contains($handlerNeedle)) {
  Write-Error "Method-handler anchor missing in AndroidARView.kt."
}
$text = $text.Replace($handlerNeedle, $handler)

$widthNeedle = '                    val physicalWidth = 0.2f // 20cm - adjust based on your actual printed image size'
$widthReplacement = @(
  '                    // lmb-plusur: physical width - fall back only if Dart sent nothing'
  '                    val physicalWidth = imageWidthsMeters[imagePath]'
  ('                        ' + (Elv) + ' imageWidthsMeters[imageName]')
  ('                        ' + (Elv) + ' 0.2f')
) -join $nl
if (-not $text.Contains($widthNeedle)) {
  Write-Error "addImage width anchor missing in AndroidARView.kt."
}
$text = $text.Replace($widthNeedle, $widthReplacement)

$cacheNeedle = "        return imagePaths.joinToString(`"|`")"
if (-not $text.Contains($cacheNeedle)) {
  $cacheNeedle = '        return imagePaths.joinToString("|")'
}
$cacheReplacement = @(
  '        val widths = imagePaths.joinToString("|") { path ->'
  ('            imageWidthsMeters[path]?.toString() ' + (Elv) + ' ""')
  '        }'
  '        return imagePaths.joinToString("|") + "#" + widths'
) -join $nl
if (-not $text.Contains($cacheNeedle)) {
  Write-Error "imageCacheKey anchor missing in AndroidARView.kt."
}
$text = $text.Replace($cacheNeedle, $cacheReplacement)

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($plugin, $text, $utf8NoBom)
Write-Output "patched: $plugin"
