import 'dart:async';
import 'dart:io';

import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ar_tracker.dart';

/// Availability probe for ARCore Augmented Images.
///
/// Only [isSupported] is implemented. Detection, the image database and 3D
/// stay in later slices and throw [UnimplementedError].
///
/// The plugin 1.1.3 has no Dart availability API, so this asks Android
/// `ArCoreApk.checkAvailability` through a one-method channel. It does not
/// add a manual `com.google.ar:core` Gradle dependency.
class ArCoreImageTracker implements ArTracker {
  static const _probe = MethodChannel('mx.lmb.plusur/arcore_probe');

  final StreamController<ArDetection> _detections =
      StreamController<ArDetection>.broadcast();

  @override
  Future<bool> isSupported() async {
    if (!Platform.isAndroid) return false;

    // Touch the plugin so this file is the sole importer and the engine
    // loads it. getPlatformVersion does not start a session.
    try {
      await ArFlutterPluginPlus.platformVersion;
    } on Object {
      return false;
    }

    if (!await _arCoreInstalled()) return false;
    return _cameraGranted();
  }

  Future<bool> _arCoreInstalled() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final String name;
      try {
        name = await _probe.invokeMethod<String>('checkAvailability') ?? '';
      } on Object {
        return false;
      }
      if (name == 'SUPPORTED_INSTALLED') return true;
      if (name != 'UNKNOWN_CHECKING') return false;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return false;
  }

  Future<bool> _cameraGranted() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied || status.isRestricted) return false;
    status = await Permission.camera.request();
    return status.isGranted;
  }

  @override
  Stream<ArDetection> get detections => _detections.stream;

  @override
  Future<void> start({required List<ArReferenceImage> references}) {
    throw UnimplementedError('ArCoreImageTracker.start is AR-05');
  }

  @override
  Future<void> attachModel({
    required String trackerName,
    required String glbAsset,
  }) {
    throw UnimplementedError('ArCoreImageTracker.attachModel is AR-06');
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    if (!_detections.isClosed) {
      await _detections.close();
    }
  }
}
