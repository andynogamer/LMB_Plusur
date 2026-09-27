package mx.lmb.plusur.lmb_plusur

import android.Manifest
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.Locale

/// Hosts the ARCore availability probe, AR photo save, and speech channels.
///
/// The probe loads ArCoreApk by reflection from the plugin's transitive dex.
/// Do not add a manual ARCore Gradle dependency (D-17).
///
/// TTS is the platform engine (es-MX); capture composes the plugin's AR-surface
/// snapshot with Flutter chrome before saving through MediaStore.
/// Roll back by removing the added method channels and photo helpers.
class MainActivity : FlutterActivity() {
    private companion object {
        const val PHOTO_PERMISSION_REQUEST = 412
    }

    private data class PendingPhotoCapture(
        val result: MethodChannel.Result,
        val arScenePng: ByteArray,
        val overlayPng: ByteArray,
    )

    private var speech: TextToSpeech? = null
    private var speechReady = false
    private var pendingUtterance: String? = null
    private var pendingPhotoPermission: PendingPhotoCapture? = null
    private var photoCaptureInProgress = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mx.lmb.plusur/arcore_probe",
        ).setMethodCallHandler { call, result ->
            if (call.method == "checkAvailability") {
                result.success(arCoreAvailabilityName())
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mx.lmb.plusur/ar_photo_capture",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkCaptureSupported" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                        result.error(
                            "unsupported_android_version",
                            "Guardar fotos AR requiere Android 8 o posterior.",
                            null,
                        )
                    } else {
                        result.success(true)
                    }
                }
                "capturePhoto" -> {
                    val arScenePng = call.argument<ByteArray>("arScenePng")
                    val overlayPng = call.argument<ByteArray>("overlayPng")
                    if (arScenePng == null || overlayPng == null) {
                        result.error(
                            "capture_failed",
                            "No pudimos capturar la vista AR.",
                            null,
                        )
                    } else {
                        capturePhoto(result, arScenePng, overlayPng)
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mx.lmb.plusur/tts",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    speak(call.argument<String>("text").orEmpty())
                    result.success(true)
                }
                "stop" -> {
                    speech?.stop()
                    pendingUtterance = null
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PHOTO_PERMISSION_REQUEST) return
        val capture = pendingPhotoPermission ?: return
        pendingPhotoPermission = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            saveCapture(capture)
        } else {
            photoCaptureInProgress = false
            capture.result.error(
                "permission_denied",
                "Se necesita permiso para guardar la foto.",
                null,
            )
        }
    }

    override fun onDestroy() {
        pendingPhotoPermission?.result?.error(
            "capture_failed",
            "La sesión AR terminó antes de guardar la foto.",
            null,
        )
        pendingPhotoPermission = null
        pendingUtterance = null
        speech?.stop()
        speech?.shutdown()
        speech = null
        speechReady = false
        super.onDestroy()
    }

    private fun capturePhoto(
        result: MethodChannel.Result,
        arScenePng: ByteArray,
        overlayPng: ByteArray,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error(
                "unsupported_android_version",
                "Guardar fotos AR requiere Android 8 o posterior.",
                null,
            )
            return
        }
        if (photoCaptureInProgress) {
            result.error("capture_in_progress", "Ya se está guardando una foto.", null)
            return
        }
        if (arScenePng.isEmpty() || overlayPng.isEmpty()) {
            result.error("capture_failed", "No pudimos capturar la vista AR.", null)
            return
        }
        photoCaptureInProgress = true
        val capture = PendingPhotoCapture(result, arScenePng, overlayPng)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            pendingPhotoPermission = capture
            requestPermissions(
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                PHOTO_PERMISSION_REQUEST,
            )
            return
        }
        saveCapture(capture)
    }

    private fun saveCapture(capture: PendingPhotoCapture) {
        Thread({
            var imageUri: Uri? = null
            var arScene: Bitmap? = null
            var overlay: Bitmap? = null
            var composed: Bitmap? = null
            try {
                arScene = BitmapFactory.decodeByteArray(
                    capture.arScenePng,
                    0,
                    capture.arScenePng.size,
                ) ?: throw IOException("AR scene snapshot is not a valid image")
                overlay = BitmapFactory.decodeByteArray(
                    capture.overlayPng,
                    0,
                    capture.overlayPng.size,
                ) ?: throw IOException("AR controls snapshot is not a valid image")
                if (!hasVisualContent(arScene!!)) {
                    throw IOException("AR scene snapshot is blank")
                }
                if (!hasVisualContent(overlay!!)) {
                    throw IOException("AR controls snapshot is blank")
                }

                composed = Bitmap.createBitmap(
                    arScene!!.width,
                    arScene!!.height,
                    Bitmap.Config.ARGB_8888,
                )
                val canvas = Canvas(composed!!)
                canvas.drawBitmap(arScene!!, 0f, 0f, null)
                canvas.drawBitmap(
                    overlay!!,
                    null,
                    Rect(0, 0, composed!!.width, composed!!.height),
                    Paint(Paint.FILTER_BITMAP_FLAG),
                )

                val timestamp = System.currentTimeMillis()
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, "LMB_AR_$timestamp.png")
                    put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        put(
                            MediaStore.Images.Media.RELATIVE_PATH,
                            "${Environment.DIRECTORY_PICTURES}/LMB Plusur",
                        )
                        put(MediaStore.Images.Media.IS_PENDING, 1)
                    }
                }
                imageUri = contentResolver.insert(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                    values,
                ) ?: throw IOException("MediaStore did not create an image")
                val output = contentResolver.openOutputStream(imageUri!!)
                    ?: throw IOException("MediaStore output stream is unavailable")
                output.use {
                    if (!composed!!.compress(Bitmap.CompressFormat.PNG, 100, it)) {
                        throw IOException("Bitmap encoding failed")
                    }
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    contentResolver.update(
                        imageUri!!,
                        ContentValues().apply {
                            put(MediaStore.Images.Media.IS_PENDING, 0)
                        },
                        null,
                        null,
                    )
                }
                runOnUiThread { capture.result.success(true) }
            } catch (_: Exception) {
                imageUri?.let { contentResolver.delete(it, null, null) }
                val errorCode = if (composed == null) {
                    "capture_failed"
                } else {
                    "gallery_save_failed"
                }
                val errorMessage = if (composed == null) {
                    "No pudimos capturar la vista AR."
                } else {
                    "No pudimos guardar la foto en la galería."
                }
                runOnUiThread {
                    capture.result.error(
                        errorCode,
                        errorMessage,
                        null,
                    )
                }
            } finally {
                arScene?.recycle()
                overlay?.recycle()
                composed?.recycle()
                runOnUiThread { photoCaptureInProgress = false }
            }
        }, "lmb-ar-photo-save").start()
    }

    private fun hasVisualContent(bitmap: Bitmap): Boolean {
        val stepX = maxOf(1, bitmap.width / 64)
        val stepY = maxOf(1, bitmap.height / 64)
        val sampledColors = mutableSetOf<Int>()
        for (y in 0 until bitmap.height step stepY) {
            for (x in 0 until bitmap.width step stepX) {
                val color = bitmap.getPixel(x, y)
                if (android.graphics.Color.alpha(color) > 10) {
                    sampledColors.add(
                        ((android.graphics.Color.red(color) shr 4) shl 8) or
                            ((android.graphics.Color.green(color) shr 4) shl 4) or
                            (android.graphics.Color.blue(color) shr 4),
                    )
                    if (sampledColors.size > 1) return true
                }
            }
        }
        return false
    }

    private fun speak(text: String) {
        val utterance = text.trim()
        if (utterance.isEmpty()) return
        val engine = speech
        if (engine == null) {
            pendingUtterance = utterance
            speech = TextToSpeech(this, this::onSpeechReady)
            return
        }
        if (!speechReady) {
            pendingUtterance = utterance
            return
        }
        engine.speak(utterance, TextToSpeech.QUEUE_FLUSH, null, "lmb-info")
    }

    private fun onSpeechReady(status: Int) {
        val engine = speech ?: return
        if (status != TextToSpeech.SUCCESS) {
            speechReady = false
            return
        }
        val locale = Locale("es", "MX")
        val available = engine.setLanguage(locale)
        if (available == TextToSpeech.LANG_MISSING_DATA ||
            available == TextToSpeech.LANG_NOT_SUPPORTED
        ) {
            engine.setLanguage(Locale("es"))
        }
        speechReady = true
        val queued = pendingUtterance
        pendingUtterance = null
        if (!queued.isNullOrEmpty()) {
            engine.speak(queued, TextToSpeech.QUEUE_FLUSH, null, "lmb-info")
        }
    }

    private fun arCoreAvailabilityName(): String {
        return try {
            val apk = Class.forName("com.google.ar.core.ArCoreApk")
            val instance = apk.getMethod("getInstance").invoke(null)
            val availability = apk
                .getMethod("checkAvailability", Context::class.java)
                .invoke(instance, this)
            availability?.toString() ?: "UNKNOWN_ERROR"
        } catch (_: Throwable) {
            "UNSUPPORTED_DEVICE_NOT_CAPABLE"
        }
    }
}
