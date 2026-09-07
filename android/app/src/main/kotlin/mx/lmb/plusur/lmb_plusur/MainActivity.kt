package mx.lmb.plusur.lmb_plusur

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Hosts a one-method probe. ar_flutter_plugin_plus 1.1.3 never exposes
/// ArCoreApk.checkAvailability, and we must not add a manual ARCore Gradle
/// dependency (D-17). The class is loaded by reflection from the plugin's
/// transitive dex. Rollback: delete this channel and restore the empty activity.
class MainActivity : FlutterActivity() {
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
