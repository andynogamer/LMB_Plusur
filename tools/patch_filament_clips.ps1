# Plays glTF clips on the pinned ar_flutter_plugin_plus 1.1.3 Filament renderer.
#
# Plugin 1.1.3 loads a GLB and never ticks Animator, so jugador.glb clips
# (idle, gesto) never move. This adds playClip on the object channel.
# Re-run after flutter pub get (pub may restore the unpatched plugin).
# Idempotent. Requires the width patch to stay applied separately.
#
# Rollback: flutter pub cache repair, or delete the plugin folder and pub get.
# Do not bump the pin. Do not write a matcher.

$ErrorActionPreference = "Stop"

$pubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else {
  Join-Path $env:LOCALAPPDATA "Pub\Cache"
}
$root = Join-Path $pubCache "hosted\pub.dev\ar_flutter_plugin_plus-1.1.3\android\src\main\kotlin\tech\graaf\franz\ar_flutter_plugin_plus"
$renderer = Join-Path $root "ModelRenderer.kt"
$view = Join-Path $root "AndroidARView.kt"

if (-not (Test-Path $renderer)) {
  Write-Error "Plugin source not found: $renderer. Run flutter pub get first."
}
if (-not (Test-Path $view)) {
  Write-Error "Plugin source not found: $view. Run flutter pub get first."
}

function Write-Plugin([string] $path, [string] $text) {
  $utf8NoBom = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
}

$rendererText = [System.IO.File]::ReadAllText($renderer)
$viewText = [System.IO.File]::ReadAllText($view)

if ($rendererText.Contains("lmb-plusur: filament clips") -and $viewText.Contains("lmb-plusur: filament clips")) {
  Write-Output "already patched: $renderer"
  exit 0
}

$nl = "`r`n"
if (-not $rendererText.Contains("`r`n")) { $nl = "`n" }

if (-not $rendererText.Contains("lmb-plusur: filament clips")) {
  $importNeedle = "import com.google.android.filament.gltfio.AssetLoader"
  $import = "import com.google.android.filament.gltfio.Animator" + $nl + $importNeedle
  if (-not $rendererText.Contains($importNeedle)) {
    Write-Error "Animator import anchor missing in ModelRenderer.kt."
  }
  $rendererText = $rendererText.Replace($importNeedle, $import)

  $fieldNeedle = "    private val pendingTransforms: MutableMap<String, FloatArray> = mutableMapOf()"
  $fields = @(
    $fieldNeedle
    ""
    "    // lmb-plusur: filament clips. Node TRS clips (idle / gesto). Not skinned."
    "    private data class ClipRequest(val clipName: String, val loop: Boolean)"
    "    private data class ActiveClip("
    "        var index: Int,"
    "        var time: Float,"
    "        var duration: Float,"
    "        var loop: Boolean,"
    "        var playing: Boolean"
    "    )"
    "    private val pendingClips: MutableMap<String, ClipRequest> = mutableMapOf()"
    "    private val activeClips: MutableMap<String, ActiveClip> = mutableMapOf()"
    "    private var lastFrameNanos: Long = 0L"
  ) -join $nl
  if (-not $rendererText.Contains($fieldNeedle)) {
    Write-Error "pendingTransforms anchor missing in ModelRenderer.kt."
  }
  $rendererText = $rendererText.Replace($fieldNeedle, $fields)

  $frameNeedle = @"
        frameCallback = Choreographer.FrameCallback {
            renderFrame()
            choreographer?.postFrameCallback(frameCallback)
        }
"@
  $frame = @"
        frameCallback = Choreographer.FrameCallback { frameTimeNanos ->
            renderFrame(frameTimeNanos)
            choreographer?.postFrameCallback(frameCallback)
        }
"@
  if (-not $rendererText.Contains($frameNeedle)) {
    Write-Error "render-loop anchor missing in ModelRenderer.kt."
  }
  $rendererText = $rendererText.Replace($frameNeedle, $frame)

  $sigNeedle = "    private fun renderFrame() {"
  if (-not $rendererText.Contains($sigNeedle)) {
    Write-Error "renderFrame signature missing in ModelRenderer.kt."
  }
  $rendererText = $rendererText.Replace($sigNeedle, "    private fun renderFrame(frameTimeNanos: Long) {")

  $beginNeedle = "        if (renderer.beginFrame(swapChain, 0L)) {"
  $begin = @(
    "        tickClips(frameTimeNanos)"
    ""
    "        if (renderer.beginFrame(swapChain, frameTimeNanos)) {"
  ) -join $nl
  if (-not $rendererText.Contains($beginNeedle)) {
    Write-Error "beginFrame anchor missing in ModelRenderer.kt."
  }
  $rendererText = $rendererText.Replace($beginNeedle, $begin)

  $afterLoad = "            modelAssets[name] = asset"
  $afterLoadPatched = @(
    $afterLoad
    "            applyPendingClip(name, asset)"
  ) -join $nl
  $loadCount = ([regex]::Matches($rendererText, [regex]::Escape($afterLoad))).Count
  if ($loadCount -lt 1) {
    Write-Error "modelAssets assignment missing in ModelRenderer.kt."
  }
  $rendererText = $rendererText.Replace($afterLoad, $afterLoadPatched)

  $removeNeedle = "            pendingTransforms.remove(name)"
  $remove = @(
    $removeNeedle
    "            pendingClips.remove(name)"
    "            activeClips.remove(name)"
  ) -join $nl
  if (-not $rendererText.Contains($removeNeedle)) {
    Write-Error "removeModel anchor missing in ModelRenderer.kt."
  }
  $rendererText = $rendererText.Replace($removeNeedle, $remove)

  $methods = @'

    // lmb-plusur: filament clips
    fun requestClip(name: String, clipName: String, loop: Boolean): Boolean {
        if (name.isEmpty() || clipName.isEmpty()) return false
        pendingClips[name] = ClipRequest(clipName, loop)
        val asset = modelAssets[name] ?: return true
        return startNamedClip(name, asset, clipName, loop)
    }

    private fun applyPendingClip(name: String, asset: FilamentAsset) {
        val request = pendingClips[name] ?: return
        startNamedClip(name, asset, request.clipName, request.loop)
    }

    private fun animatorOf(asset: FilamentAsset): Animator? {
        val instance = asset.instance ?: return null
        return instance.animator
    }

    private fun clipIndex(asset: FilamentAsset, clipName: String): Int {
        val animator = animatorOf(asset) ?: return -1
        val count = animator.animationCount
        for (i in 0 until count) {
            if (animator.getAnimationName(i) == clipName) return i
        }
        return -1
    }

    private fun startNamedClip(name: String, asset: FilamentAsset, clipName: String, loop: Boolean): Boolean {
        val index = clipIndex(asset, clipName)
        if (index < 0) {
            pendingClips.remove(name)
            return false
        }
        startIndexed(name, asset, index, loop)
        return true
    }

    private fun startIndexed(name: String, asset: FilamentAsset, index: Int, loop: Boolean) {
        val animator = animatorOf(asset) ?: return
        val duration = animator.getAnimationDuration(index)
        activeClips[name] = ActiveClip(index, 0f, duration, loop, true)
        animator.applyAnimation(index, 0f)
        animator.updateBoneMatrices()
    }

    private fun tickClips(frameTimeNanos: Long) {
        if (activeClips.isEmpty()) {
            lastFrameNanos = frameTimeNanos
            return
        }
        if (lastFrameNanos == 0L) lastFrameNanos = frameTimeNanos
        var dt = (frameTimeNanos - lastFrameNanos) / 1_000_000_000f
        if (dt < 0f) dt = 0f
        if (dt > 0.05f) dt = 0.05f
        lastFrameNanos = frameTimeNanos
        if (dt == 0f) return

        for (name in activeClips.keys.toList()) {
            val state = activeClips[name] ?: continue
            if (!state.playing) continue
            val asset = modelAssets[name] ?: continue
            val animator = animatorOf(asset) ?: continue
            state.time += dt
            if (!state.loop && state.duration > 0f && state.time >= state.duration) {
                val idleIndex = clipIndex(asset, "idle")
                if (idleIndex >= 0 && idleIndex != state.index) {
                    startIndexed(name, asset, idleIndex, true)
                } else {
                    state.playing = false
                    animator.applyAnimation(state.index, state.duration)
                    animator.updateBoneMatrices()
                }
                continue
            }
            if (state.loop && state.duration > 0f && state.time >= state.duration) {
                state.time %= state.duration
            }
            animator.applyAnimation(state.index, state.time)
            animator.updateBoneMatrices()
        }
    }

'@
  $closeNeedle = "            transformManager.setTransform(instance, modelMatrix)`r`n        }`r`n    }`r`n}"
  if (-not $rendererText.Contains($closeNeedle)) {
    $closeNeedle = "            transformManager.setTransform(instance, modelMatrix)`n        }`n    }`n}"
  }
  if (-not $rendererText.Contains("transformManager.setTransform(instance, modelMatrix)")) {
    Write-Error "applyTransform close anchor missing in ModelRenderer.kt."
  }
  $rendererText = $rendererText.TrimEnd()
  if (-not $rendererText.EndsWith("}")) {
    Write-Error "ModelRenderer.kt does not end with a class close."
  }
  $rendererText = $rendererText.Substring(0, $rendererText.LastIndexOf("}")) + $methods + $nl + "}" + $nl
  Write-Plugin $renderer $rendererText
  Write-Output "patched: $renderer"
}

$viewText = [System.IO.File]::ReadAllText($view)
if (-not $viewText.Contains("lmb-plusur: filament clips")) {
  $nlView = "`r`n"
  if (-not $viewText.Contains("`r`n")) { $nlView = "`n" }
  $handlerNeedle = '                        "removeNode" -> {'
  $handler = @(
    '                        "playClip" -> {'
    '                            // lmb-plusur: filament clips. Missing clip must not drop the session.'
    '                            val nodeName = call.argument<String>("name")'
    '                            val clipName = call.argument<String>("clip")'
    '                            val loop = call.argument<Boolean>("loop") ?: false'
    '                            if (nodeName.isNullOrEmpty() || clipName.isNullOrEmpty()) {'
    '                                result.success(false)'
    '                            } else {'
    '                                result.success(modelRenderer.requestClip(nodeName, clipName, loop))'
    '                            }'
    '                        }'
    $handlerNeedle
  ) -join $nlView
  if (-not $viewText.Contains($handlerNeedle)) {
    Write-Error "removeNode handler anchor missing in AndroidARView.kt."
  }
  $viewText = $viewText.Replace($handlerNeedle, $handler)
  Write-Plugin $view $viewText
  Write-Output "patched: $view"
}
