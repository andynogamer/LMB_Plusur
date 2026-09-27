import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../ar_tracker.dart';

/// Composes the authored model orientation onto ARCore's image pose.
///
/// Club GLBs are authored upright (Y-up), while a logo marker is a horizontal
/// image plane. Laying the model onto that plane keeps the content parallel to
/// the scanned logo. Presentation yaw then rotates around the logo normal.
Matrix4 modelPoseForImage(Matrix4 imagePose, {double presentationYaw = 0}) {
  final pose = Matrix4.fromFloat64List(imagePose.storage);
  pose.translateByDouble(0, 0.01, 0, 1);
  pose.rotateX(-math.pi / 2);
  if (presentationYaw != 0) {
    pose.rotateZ(presentationYaw);
  }
  return pose;
}

/// Same name must arrive twice inside 2 s before [ArLocked] (controller).
/// One-shot emission (`continuousImageTracking: false`) never confirms.
///
/// 200 ms keeps the second hit well inside the ≤ 2 s lock budget at 25 %
/// frame fill, without copying a pose matrix onto the UI isolate every 100 ms.
const bool kContinuousImageTracking = true;

/// See [kContinuousImageTracking].
const int kImageTrackingUpdateIntervalMs = 200;

/// Scene-graph name for the GLB attached to [trackerName].
String modelNodeName(String trackerName) => 'modelo_$trackerName';

/// Scene-graph name prefix for baseball VFX nodes (`…_0` … `…_n`).
String effectNodeName(String trackerName) => 'efecto_$trackerName';

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
bool imageIsFullyTracked({String? trackingMethod, String? trackingState}) {
  if (trackingState == 'PAUSED' || trackingState == 'STOPPED') return false;
  if (trackingMethod == 'LAST_KNOWN_POSE') return false;
  return trackingMethod == 'FULL_TRACKING';
}

/// Outcome of [ArTracker.attachModel]. Missing or failed GLB must not
/// kill the session — the overlay shows Spanish copy instead.
enum ArModelAttachKind { placed, missing, failed }

class ArModelAttach {
  const ArModelAttach(this.kind, this.trackerName);

  final ArModelAttachKind kind;
  final String trackerName;
}

/// Overlay copy when a GLB cannot be placed. Null means show the model only.
String? modelFallbackCopy(ArModelAttach? attach) {
  return switch (attach?.kind) {
    ArModelAttachKind.missing =>
      'Aún no hay modelo 3D para este marcador. El escaneo sigue activo.',
    ArModelAttachKind.failed =>
      'No pudimos colocar el modelo. El escaneo sigue activo.',
    _ => null,
  };
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
  static const _photoCapture = MethodChannel('mx.lmb.plusur/ar_photo_capture');

  final StreamController<ArDetection> _detections =
      StreamController<ArDetection>.broadcast();

  final Completer<void> _viewReady = Completer<void>();

  ARSessionManager? _session;
  ARObjectManager? _objects;
  MethodChannel? _sessionChannel;
  MethodChannel? _objectChannel;
  final Map<String, Matrix4> _poses = {};
  final Map<String, ARNode> _nodes = {};
  final Map<String, String> _nodeAssets = {};
  final List<_EffectParticle> _effectParticles = [];
  String? _effectTrackerName;
  ArParticleEffect? _activeParticleEffect;
  double _effectProgress = 0;
  double _presentationYaw = 0;
  ArModelAttach? modelAttach;
  List<ArReferenceImage> _references = const [];
  Widget? _surface;
  bool _stopped = false;
  bool _configuring = false;
  String _availability = '';

  @override
  bool get supportsPhotoCapture => Platform.isAndroid;

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

  @override
  Future<void> handleAppLifecycleChange({required bool resumed}) async {
    if (_stopped) {
      throw const ArTrackerException(ArTrackerFailure.sessionLost);
    }
    final channel = _sessionChannel;
    if (channel == null) {
      throw const ArTrackerException(ArTrackerFailure.sessionLost);
    }
    try {
      final ok = await channel.invokeMethod<bool>(
        resumed ? 'resumeSession' : 'pauseSession',
      );
      if (resumed && ok != true) {
        throw const ArTrackerException(ArTrackerFailure.sessionLost);
      }
    } on ArTrackerException {
      rethrow;
    } on MissingPluginException {
      throw const ArTrackerException(
        ArTrackerFailure.sessionLost,
        'resumeSession/pauseSession missing — re-run '
        'tools/patch_arcore_session_lifecycle.ps1',
      );
    } on PlatformException catch (error) {
      throw ArTrackerException(ArTrackerFailure.sessionLost, error);
    }
  }

  void _onViewCreated(
    ARSessionManager session,
    ARObjectManager objects,
    MethodChannel channel,
    MethodChannel objectChannel,
  ) {
    if (_stopped) return;
    _session = session;
    _objects = objects;
    _sessionChannel = channel;
    // Same channel ARObjectManager already bound. Do not set a handler here.
    _objectChannel = objectChannel;
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
    _poses[imageName] = transformation;
    final node = _nodes[imageName];
    if (node != null) {
      node.transform = _anchoredPose(transformation);
    }
    final effect = _activeParticleEffect;
    if (_effectParticles.isNotEmpty &&
        _effectTrackerName == imageName &&
        effect != null) {
      _applyEffectTransforms(
        transformation,
        progress: _effectProgress,
        effect: effect,
      );
    }
    _detections.add(
      ArDetection(
        trackerName: imageName,
        pose: transformation,
        isFullyTracked: true,
      ),
    );
  }

  /// Image pose plus a small lift so the model sits on the card, not in it.
  ///
  /// [_presentationYaw] is the información action's single spin. It is
  /// applied in local space after the lift so tracking updates keep it.
  Matrix4 _anchoredPose(Matrix4 imagePose) {
    return modelPoseForImage(imagePose, presentationYaw: _presentationYaw);
  }

  @override
  void setPresentationYaw(double radians) {
    _presentationYaw = radians;
    for (final entry in _nodes.entries) {
      final pose = _poses[entry.key];
      if (pose == null) continue;
      entry.value.transform = _anchoredPose(pose);
    }
  }

  @override
  Future<bool> playClip({
    required String trackerName,
    required String clipName,
    bool loop = false,
  }) async {
    final channel = _objectChannel;
    if (channel == null ||
        _stopped ||
        clipName.isEmpty ||
        !_nodes.containsKey(trackerName)) {
      return false;
    }
    try {
      final ok = await channel.invokeMethod<bool>('playClip', {
        'name': modelNodeName(trackerName),
        'clip': clipName,
        'loop': loop,
      });
      return ok == true;
    } on Object {
      // Missing patch or a static GLB. Do not fail the session.
      return false;
    }
  }

  @override
  Future<bool> setClipPaused({
    required String trackerName,
    required bool paused,
  }) async {
    final channel = _objectChannel;
    if (channel == null || _stopped || !_nodes.containsKey(trackerName)) {
      return false;
    }
    try {
      return await channel.invokeMethod<bool>('setClipPaused', {
            'name': modelNodeName(trackerName),
            'paused': paused,
          }) ==
          true;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> attachEffect({
    required String trackerName,
    required String glbAsset,
    required ArParticleEffect effect,
  }) async {
    final pose = _poses[trackerName];
    final objects = _objects;
    if (pose == null || objects == null || _stopped) {
      return false;
    }
    await clearEffect();
    try {
      await rootBundle.load(glbAsset);
    } on Object {
      return false;
    }

    final rng = math.Random();
    // Cap particle count for mid-tier Filament devices.
    const count = 6;
    var placed = 0;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + rng.nextDouble() * 0.35;
      final particle = _particleMotion(effect, angle, rng);
      final node = ARNode(
        type: NodeType.localGLB,
        uri: glbAsset,
        name: '${effectNodeName(trackerName)}_$i',
        transformation: _particleWorldPose(
          pose,
          particle.start,
          scale: particle.scale,
        ),
      );
      bool added;
      try {
        added = await objects.addNode(node) ?? false;
      } on Object {
        added = false;
      }
      if (!added) continue;
      _effectParticles.add(
        _EffectParticle(
          node: node,
          start: particle.start,
          velocity: particle.velocity,
          spin: particle.spin,
          scale: particle.scale,
        ),
      );
      placed += 1;
    }
    if (placed == 0) return false;
    _effectTrackerName = trackerName;
    _activeParticleEffect = effect;
    _effectProgress = 0;
    return true;
  }

  ({Vector3 start, Vector3 velocity, double spin, double scale})
      _particleMotion(ArParticleEffect effect, double angle, math.Random rng) {
    final radial = Vector3(math.cos(angle), 0, math.sin(angle));
    return switch (effect) {
      ArParticleEffect.jonron => (
          start: Vector3(radial.x * 0.006, 0.03, radial.z * 0.006),
          velocity: Vector3(radial.x * 0.07, 0.10, radial.z * 0.07),
          spin: (rng.nextDouble() - 0.5) * 8,
          scale: 0.55,
        ),
      ArParticleEffect.chispas => (
          start: Vector3(radial.x * 0.008, 0.02, radial.z * 0.008),
          velocity: Vector3(radial.x * 0.025, 0.15, radial.z * 0.025),
          spin: (rng.nextDouble() - 0.5) * 18,
          scale: 0.72,
        ),
      ArParticleEffect.confeti => (
          start: Vector3(radial.x * 0.018, 0.05, radial.z * 0.018),
          velocity: Vector3(radial.x * 0.045, 0.025, radial.z * 0.045),
          spin: (rng.nextDouble() - 0.5) * 24,
          scale: 0.8,
        ),
      ArParticleEffect.polvoDelDiamante => (
          start: Vector3(radial.x * 0.012, 0.006, radial.z * 0.012),
          velocity: Vector3(radial.x * 0.03, 0.018, radial.z * 0.03),
          spin: (rng.nextDouble() - 0.5) * 3,
          scale: 0.9,
        ),
    };
  }

  @override
  void updateEffect(double progress) {
    _effectProgress = progress.clamp(0.0, 1.0);
    final name = _effectTrackerName;
    if (name == null || _effectParticles.isEmpty) return;
    final pose = _poses[name];
    if (pose == null) return;
    _applyEffectTransforms(
      pose,
      progress: _effectProgress,
      effect: _activeParticleEffect!,
    );
  }

  @override
  Future<void> clearEffect() async {
    final objects = _objects;
    final particles = List<_EffectParticle>.from(_effectParticles);
    _effectParticles.clear();
    _effectTrackerName = null;
    _activeParticleEffect = null;
    _effectProgress = 0;
    if (objects == null) return;
    for (final particle in particles) {
      try {
        objects.removeNode(particle.node);
      } on Object {
        // Node already gone with the session.
      }
    }
  }

  void _applyEffectTransforms(
    Matrix4 imagePose, {
    required double progress,
    required ArParticleEffect effect,
  }) {
    // Hold nearly full size, then shrink away in the last quarter.
    final fade = progress < 0.72
        ? 1.0
        : (1.0 - ((progress - 0.72) / 0.28)).clamp(0.0, 1.0);
    final scale = (0.4 +
            0.7 * Curves.easeOut.transform(progress.clamp(0.0, 0.35) / 0.35)) *
        fade;
    // Soften scale near zero so Filament does not keep a speck.
    final visibleScale = fade <= 0.02 ? 0.001 : scale;

    for (final particle in _effectParticles) {
      final wobble = math.sin(progress * math.pi * 4 + particle.spin) * 0.006;
      final gravity = effect == ArParticleEffect.confeti ? -0.055 : 0.0;
      final dustDrop =
          effect == ArParticleEffect.polvoDelDiamante ? -0.004 : 0.0;
      final drift = Vector3(
        particle.start.x + particle.velocity.x * progress + wobble,
        particle.start.y +
            particle.velocity.y * progress +
            gravity * progress * progress +
            dustDrop * progress,
        particle.start.z + particle.velocity.z * progress - wobble * 0.5,
      );
      particle.node.transform = _particleWorldPose(
        imagePose,
        drift,
        scale: particle.scale * visibleScale,
        yaw: particle.spin * progress,
      );
    }
  }

  Matrix4 _particleWorldPose(
    Matrix4 imagePose,
    Vector3 local, {
    required double scale,
    double yaw = 0,
  }) {
    final pose = Matrix4.fromFloat64List(imagePose.storage);
    pose.translateByDouble(local.x, local.y, local.z, 1);
    if (yaw != 0) {
      pose.rotateY(yaw);
    }
    pose.scaleByDouble(scale, scale, scale, 1);
    return pose;
  }

  @override
  Future<void> capturePhoto({required Uint8List overlayPng}) async {
    if (!Platform.isAndroid) {
      throw const ArPhotoCaptureException(
        ArPhotoCaptureFailure.unsupportedPlatform,
      );
    }
    try {
      final supported = await _photoCapture.invokeMethod<bool>(
        'checkCaptureSupported',
      );
      if (supported != true) {
        throw const ArPhotoCaptureException(
          ArPhotoCaptureFailure.unsupportedAndroidVersion,
        );
      }
    } on ArPhotoCaptureException {
      rethrow;
    } on PlatformException catch (error) {
      if (error.code == 'unsupported_android_version') {
        throw const ArPhotoCaptureException(
          ArPhotoCaptureFailure.unsupportedAndroidVersion,
        );
      }
      throw const ArPhotoCaptureException(ArPhotoCaptureFailure.captureFailed);
    } on MissingPluginException {
      throw const ArPhotoCaptureException(ArPhotoCaptureFailure.captureFailed);
    }

    final Uint8List? scenePng;
    try {
      scenePng = await _sessionChannel?.invokeMethod<Uint8List>(
        'snapshot',
      );
    } on PlatformException {
      throw const ArPhotoCaptureException(ArPhotoCaptureFailure.captureFailed);
    } on MissingPluginException {
      throw const ArPhotoCaptureException(ArPhotoCaptureFailure.captureFailed);
    }
    if (scenePng == null || scenePng.isEmpty || overlayPng.isEmpty) {
      throw const ArPhotoCaptureException(ArPhotoCaptureFailure.captureFailed);
    }

    try {
      final saved = await _photoCapture.invokeMethod<bool>(
        'capturePhoto',
        <String, Uint8List>{
          'arScenePng': scenePng,
          'overlayPng': overlayPng,
        },
      );
      if (saved != true) {
        throw const ArPhotoCaptureException(ArPhotoCaptureFailure.saveFailed);
      }
    } on ArPhotoCaptureException {
      rethrow;
    } on PlatformException catch (error) {
      final failure = switch (error.code) {
        'unsupported_android_version' =>
          ArPhotoCaptureFailure.unsupportedAndroidVersion,
        'permission_denied' => ArPhotoCaptureFailure.permissionDenied,
        'capture_failed' => ArPhotoCaptureFailure.captureFailed,
        _ => ArPhotoCaptureFailure.saveFailed,
      };
      throw ArPhotoCaptureException(failure);
    }
  }

  ArTrackerFailure _availabilityFailure() {
    return switch (_availability) {
      'SUPPORTED_NOT_INSTALLED' ||
      'SUPPORTED_APK_TOO_OLD' =>
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
  }) async {
    final pose = _poses[trackerName];
    if (pose == null) {
      // Not fully tracked yet — do not place.
      return;
    }
    final existing = _nodes[trackerName];
    if (existing != null && _nodeAssets[trackerName] == glbAsset) {
      existing.transform = _anchoredPose(pose);
      modelAttach = ArModelAttach(ArModelAttachKind.placed, trackerName);
      return;
    }
    if (existing != null) {
      final objects = _objects;
      if (objects == null) {
        modelAttach = ArModelAttach(ArModelAttachKind.failed, trackerName);
        return;
      }
      await objects.removeNode(existing);
      _nodes.remove(trackerName);
      _nodeAssets.remove(trackerName);
    }
    try {
      await rootBundle.load(glbAsset);
    } on Object {
      modelAttach = ArModelAttach(ArModelAttachKind.missing, trackerName);
      return;
    }
    final objects = _objects;
    if (objects == null || _stopped) {
      modelAttach = ArModelAttach(ArModelAttachKind.failed, trackerName);
      return;
    }
    final node = ARNode(
      type: NodeType.localGLB,
      uri: glbAsset,
      name: modelNodeName(trackerName),
      transformation: _anchoredPose(pose),
    );
    final bool added;
    try {
      added = await objects.addNode(node) ?? false;
    } on Object {
      modelAttach = ArModelAttach(ArModelAttachKind.failed, trackerName);
      return;
    }
    if (!added) {
      modelAttach = ArModelAttach(ArModelAttachKind.failed, trackerName);
      return;
    }
    _nodes[trackerName] = node;
    _nodeAssets[trackerName] = glbAsset;
    modelAttach = ArModelAttach(ArModelAttachKind.placed, trackerName);
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    await clearEffect();
    _nodes.clear();
    _nodeAssets.clear();
    _poses.clear();
    _objects = null;
    _presentationYaw = 0;
    modelAttach = null;
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

class _EffectParticle {
  _EffectParticle({
    required this.node,
    required this.start,
    required this.velocity,
    required this.spin,
    required this.scale,
  });

  final ARNode node;
  final Vector3 start;
  final Vector3 velocity;
  final double spin;
  final double scale;
}

class _ArCoreSurface extends StatelessWidget {
  const _ArCoreSurface({required this.onCreated});

  final void Function(
    ARSessionManager session,
    ARObjectManager objects,
    MethodChannel channel,
    MethodChannel objectChannel,
  ) onCreated;

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      key: const Key('ar-camera-surface'),
      viewType: 'ar_flutter_plugin_plus',
      layoutDirection: TextDirection.ltr,
      creationParams: const <String, dynamic>{},
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (id) {
        final objects = ARObjectManager(id);
        objects.onInitialize(androidScaleFactor: 1, iosScaleFactor: 1);
        onCreated(
          ARSessionManager(id, context, PlaneDetectionConfig.none),
          objects,
          MethodChannel('arsession_$id'),
          MethodChannel('arobjects_$id'),
        );
      },
    );
  }
}
