import 'dart:async';

import 'package:flutter/foundation.dart';

@immutable
class StatsSnapshot {
  const StatsSnapshot({
    required this.inning,
    required this.localScore,
    required this.visitantScore,
    required this.localHits,
    required this.visitantHits,
  });

  final int inning;
  final int localScore;
  final int visitantScore;
  final int localHits;
  final int visitantHits;
}

/// Generates local-only baseball stats for the prototype.
class StatsSimulator extends ChangeNotifier {
  StatsSimulator({
    required this.teamId,
    Duration interval = const Duration(seconds: 3),
  }) : _interval = interval {
    _snapshot = _initialSnapshot(teamId);
    _timer = Timer.periodic(_interval, (_) => _advance());
  }

  final String teamId;
  final Duration _interval;
  late StatsSnapshot _snapshot;
  late final Timer _timer;
  int _tick = 0;

  StatsSnapshot get snapshot => _snapshot;

  void _advance() {
    _tick++;
    final scorePlay = _tick % 3 == 0;
    _snapshot = StatsSnapshot(
      inning: _snapshot.inning == 9 ? 1 : _snapshot.inning + 1,
      localScore: _snapshot.localScore + (scorePlay && _tick.isEven ? 1 : 0),
      visitantScore:
          _snapshot.visitantScore + (scorePlay && !_tick.isEven ? 1 : 0),
      localHits: _snapshot.localHits + 1,
      visitantHits: _snapshot.visitantHits + (_tick.isEven ? 1 : 0),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  static StatsSnapshot _initialSnapshot(String teamId) {
    final seed = teamId.codeUnits.fold<int>(0, (total, code) => total + code);
    return StatsSnapshot(
      inning: 1,
      localScore: seed % 3,
      visitantScore: (seed ~/ 3) % 3,
      localHits: 2 + seed % 4,
      visitantHits: 1 + seed % 3,
    );
  }
}
