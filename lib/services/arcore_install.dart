import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum ArCoreInstallStatus {
  installed,
  installRequested,
  declined,
  unsupported,
}

/// Asks Google to enable the AR camera component in-app.
///
/// This is not a second app the user has to find. On a supported phone,
/// [requestInstall] opens Google's own sheet (or is already a no-op).
class ArCoreInstall {
  static const MethodChannel _channel = MethodChannel('lmb_plusur/arcore');

  static Future<ArCoreInstallStatus> ensure() async {
    if (kIsWeb || !Platform.isAndroid) {
      return ArCoreInstallStatus.unsupported;
    }
    try {
      final raw = await _channel.invokeMethod<String>('ensureInstalled');
      switch (raw) {
        case 'installed':
          return ArCoreInstallStatus.installed;
        case 'install_requested':
          return ArCoreInstallStatus.installRequested;
        case 'declined':
          return ArCoreInstallStatus.declined;
        default:
          return ArCoreInstallStatus.unsupported;
      }
    } on MissingPluginException {
      return ArCoreInstallStatus.unsupported;
    } on PlatformException {
      return ArCoreInstallStatus.unsupported;
    }
  }
}
