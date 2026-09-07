import 'dart:async';
import 'dart:io';

import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ar_tracker.dart';


/// Same name must arrive twice inside 2 s before [ArLocked] (controller).
/// One-shot emission (`continuousImageTracking: false`) never confirms.
///
/// 200 ms keeps the second hit well inside the ≤ 2 s lock budget at 25 %
/// frame fill, without copying a pose matrix onto the UI isolate every 100 ms.
const bool kContinuousImageTracking = true;

/// See [kContinuousImageTracking].
const int kImageTrackingUpdateIntervalMs = 200;

/// Filename stem ARCore stores as the reference-image name.
///
/// Must equal [ArReferenceImage.name] / `Marcador.id`. No rewriting.
String referenceImageStem(String assetPath) {
  final file = assetPath.split('/').last;
  final dot = file.lastIndexOf('.');
  return dot <= 0 ? file : file.substring(0, dot);
}

/// Plugin 1.1.3 only reports `TrackingMethod.FULL_TRACKING`. A paused or
/// stopped image is never fully tracked — do not place content on it.
bool imageIsFullyTracked({
  String? trackingMethod,
  String? trackingState,
}) {
  if (trackingState == 'PAUSED' || trackingState == 'STOPPED') return false;
  if (trackingMethod == 'LAST_KNOWN_POSE') return false;
  return trackingMethod == 'FULL_TRACKING';
}

/// Rejects a database that cannot be built. Does not read pixels.
void assertTrackableReferences(List<ArReferenceImage> references) {
  if (references.isEmpty) {
    throw const ArTrackerException(
      ArTrackerFailure.databaseBuildFailed,
      'no reference images',
    );
  }
  for (final reference in references) {
    if (reference.physicalWidthMeters <= 0 ||
        reference.name.isEmpty ||
        reference.assetPath.isEmpty ||
        referenceImageStem(reference.assetPath) != reference.name) {
      throw ArTrackerException(
        ArTrackerFailure.databaseBuildFailed,
        'reference name must equal filename stem and anchoMetros must be > 0 '
            '(${reference.name})',
      );
    }
  }
}

/// ARCore Augmented Images behind [ArTracker].
///
/// Dart never decodes a frame and never compares logos. The only identity
/// that leaves this class is the reference-image name ARCore reports.
///
/// Plugin 1.1.3 hardcodes physical width at 0.2 m and ignores Dart arguments.
/// [start] therefore sends each [ArReferenceImage.physicalWidthMeters] on
/// `setImageWidths` before the image database is built. That method exists
/// only after `tools/patch_arcore_image_width.ps1` (re-run after `pub get`).
class ArCoreImageTracker implements ArTracker {
  static const _probe = MethodChannel('mx.lmb.plusur/arcore_probe');

  final StreamController<ArDetection> _detections =
      StreamController<ArDetection>.broadcast();

  final Completer<void> _viewReady = Completer<void>();

  ARSessionManager? _session;
  MethodChannel? _sessionChannel;
  List<ArReferenceImage> _references = const [];
  Widget? _surface;
  bool _stopped = false;
  bool _configuring = false;
  String _availability = '';

  /// Camera platform view. The screen stacks chrome on top. Do not import
  /// the plugin from the screen — call this instead.
  Widget buildSurface() {
    return _surface ??= _ArCoreSurface(onCreated: _onViewCreated);
  }

  @override
  Future<bool> isSupported() async {
    if (!Platform.isAndroid) return false;

    // Touch the plugin so this file stays the sole importer. Does not start
    // a session.
    try {
      await ArFlutterPluginPlus.platformVersion;
    } on Object {
      return false;
    }

    return _arCoreInstalled();
  }

  /// Requests the camera. Call before [buildSurface] so the platform view
  /// never opens without a grant. Failure is reported from [start].
  Future<bool> prepareCamera() => _cameraGranted();

  Future<bool> _arCoreInstalled() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final String name;
      try {
        name = await _probe.invokeMethod<String>('checkAvailability') ?? '';
      } on Object {
        _availability = '';
        return false;
      }
      _availability = name;
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
  Future<void> start({required List<ArReferenceImage> references}) async {
    if (_stopped) {
      throw const ArTrackerException(ArTrackerFailure.sessionLost);
    }
    assertTrackableReferences(references);
    _references = List<ArReferenceImage>.unmodifiable(references);

    if (!await isSupported()) {
      throw ArTrackerException(_availabilityFailure());
    }
    if (!await prepareCamera()) {
      throw const ArTrackerException(ArTrackerFailure.permissionDenied);
    }

    try {
      await _viewReady.future.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ArTrackerException(
        ArTrackerFailure.sessionLost,
        'AR surface never attached',
      );
    }
    if (_stopped) {
      throw const ArTrackerException(ArTrackerFailure.sessionLost);
    }
    final session = _session;
    if (session == null) {
      throw const ArTrackerException(ArTrackerFailure.sessionLost);
    }
    await _configure(session);
  }

  void _onViewCreated(ARSessionManager session, MethodChannel channel) {
    if (_stopped) return;
    _session = session;
    _sessionChannel = channel;
    if (!_viewReady.isCompleted) _viewReady.complete();
  }

  Future<void> _configure(ARSessionManager session) async {
    if (_configuring || _stopped) return;
    _configuring = true;

    session.onImageDetected = _onImageDetected;
    final configured = Completer<bool>();
    session.onImageTrackingConfigured = (success) {
      if (!configured.isCompleted) configured.complete(success);
    };

    try {
      await _sendPhysicalWidths();

      // Session must exist before precompile (the channel errors otherwise).
      // Do NOT pass trackingImagePaths here — raw paths without a compiled
      // database is the known non-detection path (architecture §11).
      await session.onInitialize(
        showAnimatedGuide: false,
        showFeaturePoints: false,
        showPlanes: false,
        showWorldOrigin: false,
        handleTaps: false,
        trackingImagePaths: null,
        continuousImageTracking: kContinuousImageTracking,
        imageTrackingUpdateIntervalMs: kImageTrackingUpdateIntervalMs,
      );

      final paths = [for (final reference in _references) reference.assetPath];
      final compiled = await session.precompileImageTrackingDatabase(paths);
      if (!compiled) {
        throw const ArTrackerException(
          ArTrackerFailure.databaseBuildFailed,
          'precompileImageTrackingDatabase returned false',
        );
      }

      await session.updateImageTrackingSettings(
        trackingImagePaths: paths,
        continuousImageTracking: kContinuousImageTracking,
        imageTrackingUpdateIntervalMs: kImageTrackingUpdateIntervalMs,
      );

      final applied = await configured.future.timeout(
        const Duration(seconds: 20),
      );
      if (!applied) {
        throw const ArTrackerException(
          ArTrackerFailure.databaseBuildFailed,
          'image database was not applied',
        );
      }
    } on ArTrackerException {
      rethrow;
    } on TimeoutException {
      throw const ArTrackerException(
        ArTrackerFailure.databaseBuildFailed,
        'image database configure timed out',
      );
    } on Object catch (error) {
      throw ArTrackerException(_failureFor(error), error);
    }
  }

  /// Sends printed widths before the database is built. Plugin 1.1.3 ignores
  /// this until the width patch is applied; a missing method is a hard failure
  /// so we never silently track at the plugin's 0.2 m default.
  Future<void> _sendPhysicalWidths() async {
    final channel = _sessionChannel;
    if (channel == null) {
      throw const ArTrackerException(ArTrackerFailure.sessionLost);
    }
    final widths = <String, double>{
      for (final reference in _references)
        reference.assetPath: reference.physicalWidthMeters,
    };
    try {
      final ok = await channel.invokeMethod<bool>('setImageWidths', {
        'widthsByPath': widths,
      });
      if (ok != true) {
        throw const ArTrackerException(
          ArTrackerFailure.databaseBuildFailed,
          'setImageWidths was not applied — run tools/patch_arcore_image_width.ps1',
        );
      }
    } on PlatformException catch (error) {
      throw ArTrackerException(
        ArTrackerFailure.databaseBuildFailed,
        'setImageWidths unavailable (${error.code}): '
            'run tools/patch_arcore_image_width.ps1',
      );
    }
  }

  /// ARCore's reference-image name, unchanged. Unknown names are the
  /// controller's problem (exact miss → keep searching).
  void _onImageDetected(String imageName, Matrix4 transformation) {
    if (_stopped || _detections.isClosed) return;
    // This callback is FULL_TRACKING only. Never mark a paused image fully
    // tracked, even if a future plugin starts forwarding other states here.
    if (!imageIsFullyTracked(
      trackingMethod: 'FULL_TRACKING',
      trackingState: 'TRACKING',
    )) {
      return;
    }
    _detections.add(
      ArDetection(
        trackerName: imageName,
        pose: transformation,
        isFullyTracked: true,
      ),
    );
  }

  ArTrackerFailure _availabilityFailure() {
    return switch (_availability) {
      'SUPPORTED_NOT_INSTALLED' || 'SUPPORTED_APK_TOO_OLD' =>
        ArTrackerFailure.arCoreNeedsInstall,
      _ => ArTrackerFailure.arCoreUnavailable,
    };
  }

  ArTrackerFailure _failureFor(Object error) {
    final text = error.toString();
    if (text.contains('not installed') || text.contains('APK too old')) {
      return ArTrackerFailure.arCoreNeedsInstall;
    }
    if (text.contains('not compatible') || text.contains('not supported')) {
      return ArTrackerFailure.arCoreUnavailable;
    }
    return ArTrackerFailure.unknown;
  }

  @override
  Future<void> attachModel({
    required String trackerName,
    required String glbAsset,
  }) {
    throw UnimplementedError('ArCoreImageTracker.attachModel is AR-06');
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    final session = _session;
    _session = null;
    if (session != null) {
      try {
        await session.dispose();
      } on Object {
        // Session already torn down with the platform view.
      }
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    if (!_viewReady.isCompleted) {
      _viewReady.completeError(
        const ArTrackerException(ArTrackerFailure.sessionLost),
      );
    }
    if (!_detections.isClosed) {
      await _detections.close();
    }
  }
}

class _ArCoreSurface extends StatelessWidget {
  const _ArCoreSurface({required this.onCreated});

  final void Function(ARSessionManager session, MethodChannel channel)
      onCreated;

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      key: const Key('ar-camera-surface'),
      viewType: 'ar_flutter_plugin_plus',
      layoutDirection: TextDirection.ltr,
      creationParams: const <String, dynamic>{},
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (id) {
        onCreated(
          ARSessionManager(id, context, PlaneDetectionConfig.none),
          MethodChannel('arsession_$id'),
        );
      },
    );
  }
}
