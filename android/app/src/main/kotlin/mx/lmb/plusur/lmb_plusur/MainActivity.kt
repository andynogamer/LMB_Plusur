package mx.lmb.plusur.lmb_plusur

import com.google.ar.core.ArCoreApk
import com.google.ar.core.exceptions.UnavailableDeviceNotCompatibleException
import com.google.ar.core.exceptions.UnavailableUserDeclinedInstallationException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Triggers Google's in-app ARCore install sheet (same path as other AR apps).
/// The user should never have to hunt for "Play Services for AR" themselves.
class MainActivity : FlutterActivity() {
    private val channelName = "lmb_plusur/arcore"
    private var userRequestedInstall = true

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "ensureInstalled") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val status = ArCoreApk.getInstance()
                        .requestInstall(this, userRequestedInstall)
                    if (status == ArCoreApk.InstallStatus.INSTALL_REQUESTED) {
                        userRequestedInstall = false
                        result.success("install_requested")
                    } else {
                        result.success("installed")
                    }
                } catch (_: UnavailableDeviceNotCompatibleException) {
                    result.success("unsupported")
                } catch (_: UnavailableUserDeclinedInstallationException) {
                    result.success("declined")
                } catch (_: Exception) {
                    result.success("unsupported")
                }
            }
    }
}
