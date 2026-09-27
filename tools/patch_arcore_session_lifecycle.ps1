# Exposes ARCore session pause/resume on the pinned plugin 1.1.3.
#
# Flutter Activity callbacks can leave GLSurfaceView paused while Filament
# still draws, which is the black-preview / live-model desync (BUG-08).
# Dart drives pauseSession / resumeSession on arsession_$id after this patch.
# Re-run after flutter pub get. Idempotent.
#
# Rollback: flutter pub cache repair, or delete the plugin folder and pub get.
# Do not bump the pin. Do not set isDebuggable = false.

$ErrorActionPreference = "Stop"

$pubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else {
  Join-Path $env:LOCALAPPDATA "Pub\Cache"
}
$plugin = Join-Path $pubCache "hosted\pub.dev\ar_flutter_plugin_plus-1.1.3\android\src\main\kotlin\tech\graaf\franz\ar_flutter_plugin_plus\AndroidARView.kt"

if (-not (Test-Path $plugin)) {
  Write-Error "Plugin source not found: $plugin. Run flutter pub get first."
}

$text = [System.IO.File]::ReadAllText($plugin)
if ($text.Contains("lmb-plusur: session lifecycle")) {
  Write-Output "already patched: $plugin"
  exit 0
}

$handlerNeedle = @'
                        "dispose" -> {
                            dispose()
                        }
'@
$handler = @'
                        "pauseSession" -> {
                            // lmb-plusur: session lifecycle. Dart pauses after
                            // AppLifecycleState.paused without disposing the view.
                            onPause()
                            result.success(true)
                        }
                        "resumeSession" -> {
                            // lmb-plusur: session lifecycle
                            onResume()
                            result.success(isSessionResumed)
                        }
                        "dispose" -> {
                            dispose()
                        }
'@
if (-not $text.Contains($handlerNeedle)) {
  Write-Error "dispose handler anchor missing in AndroidARView.kt."
}
$text = $text.Replace($handlerNeedle, $handler)

$resumeNeedle = @'
    fun onResume() {
        glSurfaceView.onResume()
        if (!renderer.isSurfaceCreated) {
            pendingSessionResume = true
            return
        }
        resumeSessionInternal()
    }

    fun onPause() {
        // hide instructions view if no longer required
        if (showAnimatedGuide){
            animatedGuide?.let { guide ->
                val view = activity.findViewById(R.id.content) as ViewGroup
                view.removeView(guide)
            }
            showAnimatedGuide = false
        }
        glSurfaceView.onPause()
        activeAugmentedImages.clear()
        lastAugmentedImageUpdateMs.clear()
        isSessionResumed = false
    }

    private fun resumeSessionInternal() {
        try {
            session?.resume()
            isSessionResumed = true
            pendingSessionResume = false
        } catch (e: Exception) {
            Log.e(TAG, "Error resuming session: ${e.message}")
        }
    }
'@
$resume = @'
    fun onResume() {
        glSurfaceView.onResume()
        if (!renderer.isSurfaceCreated) {
            pendingSessionResume = true
            return
        }
        resumeSessionInternal()
    }

    fun onPause() {
        // lmb-plusur: session lifecycle - pause ARCore with the GL surface
        if (showAnimatedGuide){
            animatedGuide?.let { guide ->
                val view = activity.findViewById(R.id.content) as ViewGroup
                view.removeView(guide)
            }
            showAnimatedGuide = false
        }
        try {
            session?.pause()
        } catch (e: Exception) {
            Log.e(TAG, "Error pausing session: ${e.message}")
        }
        glSurfaceView.onPause()
        activeAugmentedImages.clear()
        lastAugmentedImageUpdateMs.clear()
        isSessionResumed = false
    }

    private fun resumeSessionInternal() {
        val current = session
        if (current == null) {
            pendingSessionResume = true
            isSessionResumed = false
            return
        }
        if (isSessionResumed) {
            pendingSessionResume = false
            return
        }
        try {
            current.resume()
            isSessionResumed = true
            pendingSessionResume = false
        } catch (e: SessionNotPausedException) {
            isSessionResumed = true
            pendingSessionResume = false
        } catch (e: Exception) {
            Log.e(TAG, "Error resuming session: ${e.message}")
            isSessionResumed = false
        }
    }
'@
if (-not $text.Contains($resumeNeedle)) {
  Write-Error "onResume/onPause anchor missing in AndroidARView.kt."
}
$text = $text.Replace($resumeNeedle, $resume)

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($plugin, $text, $utf8NoBom)
Write-Output "patched: $plugin"
