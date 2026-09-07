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
