import 'dart:async';

import '../models/equipo_model.dart';
import '../models/marcador_model.dart';
import 'ar_session_state.dart';
import 'ar_tracker.dart';
import 'marker_registry.dart';

/// Same [trackerName] must arrive [needed] consecutive times inside [window]
/// before a candidate may lock. Clock is injectable so tests need no device.
class _DetectionGate {
  _DetectionGate({
    required this.needed,
    required this.window,
    required this.now,
  });

  final int needed;
  final Duration window;
  final DateTime Function() now;

  String? _name;
  int _hits = 0;
  DateTime? _windowStart;

  void reset() {
    _name = null;
    _hits = 0;
    _windowStart = null;
  }

  /// Records one observation of [name]. Returns the consecutive hit count
  /// inside the current window. A different name, or a hit after the window,
  /// restarts the count at 1.
  int observe(String name) {
    final instant = now();
    final expired = _windowStart != null &&
        instant.difference(_windowStart!) > window;
    if (_name != name || expired) {
      _name = name;
      _hits = 1;
      _windowStart = instant;
      return _hits;
    }
    _hits += 1;
    return _hits;
  }
}

/// Owns the only legal AR transitions. Widgets read [state]; they do not
/// keep detection booleans of their own.
class ArSessionController {
  ArSessionController({
    required ArTracker tracker,
    required MarkerRegistry registry,
    this.hintEquipo,
    this.isDemo = false,
    this.needed = 2,
    this.window = const Duration(seconds: 2),
    DateTime Function()? now,
  })  : _tracker = tracker,
        _registry = registry,
        _now = now ?? DateTime.now {
    _gate = _DetectionGate(needed: needed, window: window, now: _now);
  }

  final ArTracker _tracker;
  final MarkerRegistry _registry;
  final Equipo? hintEquipo;
  final bool isDemo;
  final int needed;
  final Duration window;
  final DateTime Function() _now;

  late final _DetectionGate _gate;
  final StreamController<ArSessionState> _states =
      StreamController<ArSessionState>.broadcast();

  StreamSubscription<ArDetection>? _detections;
  ArSessionState _state = const ArPreparing();
  bool _disposed = false;
  bool _started = false;

  ArSessionState get state => _state;

  Stream<ArSessionState> get states => _states.stream;

  /// Leaves [ArPreparing] for [ArSearching], or [ArFailed] if the tracker
  /// cannot start. Never locks from here — content requires a detection.
  Future<void> start({required List<ArReferenceImage> references}) async {
    if (_disposed || _started) return;
    _started = true;
    _emit(const ArPreparing());

    try {
      final supported = await _tracker.isSupported();
      if (_disposed) return;
      if (!supported) {
        _fail(ArTrackerFailure.arCoreUnavailable);
        return;
      }
      await _tracker.start(references: references);
    } on ArTrackerException catch (error) {
      if (!_disposed) _fail(error.failure);
      return;
    } catch (_) {
      if (!_disposed) _fail(ArTrackerFailure.unknown);
      return;
    }

    if (_disposed) return;
    _detections = _tracker.detections.listen(
      _onDetection,
      onError: _onTrackerError,
    );
    _emit(ArSearching(hintEquipo: hintEquipo));
  }

  /// Cancels the detection subscription and stops the tracker.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _detections?.cancel();
    _detections = null;
    await _tracker.stop();
    await _tracker.dispose();
    if (!_states.isClosed) {
      await _states.close();
    }
  }

  void _onDetection(ArDetection detection) {
    if (_disposed || _state is ArFailed || _state is ArPreparing) return;

    final marcador = _registry.resolve(detection.trackerName);
    if (marcador == null) {
      _onUnknown();
      return;
    }

    if (!detection.isFullyTracked) {
      _onNotLocalized(marcador);
      return;
    }

    switch (_state) {
      case ArPreparing():
      case ArFailed():
        return;
      case ArSearching():
        _advanceFromSearch(marcador);
      case ArCandidate(marcador: final current):
        if (current.id != marcador.id) {
          // Different marker: drop the candidate. This hit does not start
          // a new one — the next identical pair may.
          _gate.reset();
          _emit(ArSearching(hintEquipo: hintEquipo));
          return;
        }
        _confirmOrLock(marcador);
      case ArLocked():
        return;
      case ArLost(marcador: final locked):
        if (locked.id == marcador.id) {
          _emit(ArLocked(marcador: marcador, isDemo: isDemo));
        }
    }
  }

  void _advanceFromSearch(Marcador marcador) {
    final hits = _gate.observe(marcador.id);
    if (hits >= needed) {
      _emit(ArLocked(marcador: marcador, isDemo: isDemo));
      return;
    }
    _emit(ArCandidate(marcador: marcador, hits: hits, needed: needed));
  }

  void _confirmOrLock(Marcador marcador) {
    final hits = _gate.observe(marcador.id);
    if (hits >= needed) {
      _emit(ArLocked(marcador: marcador, isDemo: isDemo));
      return;
    }
    _emit(ArCandidate(marcador: marcador, hits: hits, needed: needed));
  }

  void _onUnknown() {
    if (_state is ArCandidate) {
      _gate.reset();
      _emit(ArSearching(hintEquipo: hintEquipo));
    }
  }

  void _onNotLocalized(Marcador marcador) {
    final current = _state;
    if (current is ArLocked && current.marcador.id == marcador.id) {
      _emit(ArLost(marcador: marcador));
    }
  }

  void _onTrackerError(Object error, StackTrace stackTrace) {
    if (_disposed || _state is ArFailed) return;
    if (error is ArTrackerException) {
      _fail(error.failure);
      return;
    }
    _fail(ArTrackerFailure.unknown);
  }

  void _fail(ArTrackerFailure failure) {
    _gate.reset();
    unawaited(_detections?.cancel());
    _detections = null;
    _emit(ArFailed(failure: failure));
  }

  void _emit(ArSessionState next) {
    if (_disposed) return;
    _state = next;
    if (!_states.isClosed) {
      _states.add(next);
    }
  }
}
