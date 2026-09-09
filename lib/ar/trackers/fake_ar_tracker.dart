import 'dart:async';

import 'package:vector_math/vector_math_64.dart';

import '../ar_tracker.dart';

/// Scripted tracker for tests and demo mode.
///
/// Cycles every reference passed to [start]. It never invents a club when
/// the list is empty, and it never prefers one registered marker over the rest.
class FakeArTracker implements ArTracker {
  FakeArTracker({
    this.supported = true,
    this.startFailure,
  });

  final bool supported;
  final ArTrackerException? startFailure;

  /// Sync so a scripted [emit] is applied before the call returns. The
  /// production tracker is chatty; debouncing stays in the controller.
  final StreamController<ArDetection> _detections =
      StreamController<ArDetection>.broadcast(sync: true);

  List<ArReferenceImage> _references = const [];
  bool _stopped = false;
  bool stopCalled = false;

  /// Names emitted by [emitRegisteredCycle], in order.
  final List<String> cycledNames = [];

  /// Clips requested through [playClip], in order. Tests assert actions
  /// without a Filament session.
  final List<({String trackerName, String clipName, bool loop})> playedClips =
      [];

  /// Effect attach/clear calls for tests.
  final List<({String trackerName, String glbAsset})> attachedEffects = [];
  int clearEffectCount = 0;

  double presentationYaw = 0;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Stream<ArDetection> get detections => _detections.stream;

  @override
  Future<void> start({required List<ArReferenceImage> references}) async {
    if (startFailure != null) {
      throw startFailure!;
    }
    _references = List<ArReferenceImage>.unmodifiable(references);
    _stopped = false;
  }

  @override
  Future<void> attachModel({
    required String trackerName,
    required String glbAsset,
  }) async {}

  @override
  Future<bool> playClip({
    required String trackerName,
    required String clipName,
    bool loop = false,
  }) async {
    if (_stopped || clipName.isEmpty) return false;
    playedClips.add((
      trackerName: trackerName,
      clipName: clipName,
      loop: loop,
    ));
    return true;
  }

  @override
  Future<bool> attachEffect({
    required String trackerName,
    required String glbAsset,
  }) async {
    if (_stopped || glbAsset.isEmpty) return false;
    attachedEffects.add((trackerName: trackerName, glbAsset: glbAsset));
    effectProgress = 0;
    return true;
  }

  double effectProgress = 0;

  @override
  void updateEffect(double progress) {
    effectProgress = progress;
  }

  @override
  Future<void> clearEffect() async {
    clearEffectCount += 1;
    effectProgress = 0;
  }

  @override
  void setPresentationYaw(double radians) {
    presentationYaw = radians;
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
    _stopped = true;
  }

  @override
  Future<void> dispose() async {
    _stopped = true;
    if (!_detections.isClosed) {
      await _detections.close();
    }
  }

  /// Pushes one fully-tracked detection. Ignored after [stop] or [dispose].
  void emit(ArDetection detection) {
    if (_stopped || _detections.isClosed) return;
    _detections.add(detection);
  }

  /// Pushes a tracker failure onto the detection stream (after start).
  void fail(ArTrackerFailure failure, [Object? cause]) {
    if (_stopped || _detections.isClosed) return;
    _detections.addError(ArTrackerException(failure, cause));
  }

  /// Emits one detection for every reference given to [start], in that order.
  ///
  /// An empty database emits nothing — it does not fall back to a club.
  void emitRegisteredCycle() {
    for (final reference in _references) {
      cycledNames.add(reference.name);
      emit(
        ArDetection(
          trackerName: reference.name,
          pose: Matrix4.identity(),
          isFullyTracked: true,
        ),
      );
    }
  }
}
