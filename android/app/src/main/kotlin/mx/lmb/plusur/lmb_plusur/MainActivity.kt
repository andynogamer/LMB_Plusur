package mx.lmb.plusur.lmb_plusur

import android.content.Context
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/// Hosts the ARCore availability probe and the AR-07 speech channel.
///
/// The probe loads ArCoreApk by reflection from the plugin's transitive dex.
/// Do not add a manual ARCore Gradle dependency (D-17).
///
/// TTS is the platform engine (es-MX). Rollback: delete both channels and
/// restore the empty activity. Do not add a TTS plugin for this.
class MainActivity : FlutterActivity() {
    private var speech: TextToSpeech? = null
    private var speechReady = false
    private var pendingUtterance: String? = null

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

    override fun onDestroy() {
        pendingUtterance = null
        speech?.stop()
        speech?.shutdown()
        speech = null
        speechReady = false
        super.onDestroy()
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
