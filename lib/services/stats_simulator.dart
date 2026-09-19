import 'dart:async';

import 'package:flutter/foundation.dart';

@immutable
class StatsSnapshot {
  const StatsSnapshot({
    required this.inning,
    required this.esParteLocal,
    required this.outsCount,
    required this.localScore,
    required this.visitantScore,
    required this.localHits,
    required this.visitantHits,
    required this.finalizado,
  });

  final int inning;
  final bool esParteLocal;
  final int outsCount;
  final int localScore;
  final int visitantScore;
  final int localHits;
  final int visitantHits;
  final bool finalizado;

  String get mitad => esParteLocal ? 'Baja' : 'Alta';
}

/// Simulates plate appearances with real baseball inning rules.
///
/// The sequence is deterministic per team, but the game still has three outs
/// per half-inning, runners that advance, and a possible final score.
class StatsSimulator extends ChangeNotifier {
  StatsSimulator({
    required this.teamId,
    Duration interval = const Duration(seconds: 3),
  }) : _interval = interval {
    _seed = teamId.codeUnits.fold<int>(17, (total, code) => total * 31 + code);
    _snapshot = const StatsSnapshot(
      inning: 1,
      esParteLocal: false,
      outsCount: 0,
      localScore: 0,
      visitantScore: 0,
      localHits: 0,
      visitantHits: 0,
      finalizado: false,
    );
    _timer = Timer.periodic(_interval, (_) => _advance());
  }

  final String teamId;
  final Duration _interval;
  late final Timer _timer;
  late StatsSnapshot _snapshot;
  late int _seed;
  int _bases = 0;

  StatsSnapshot get snapshot => _snapshot;

  void _advance() {
    if (_snapshot.finalizado) return;

    final outcome = _nextInt(100);
    var outs = _snapshot.outsCount;
    var localScore = _snapshot.localScore;
    var visitantScore = _snapshot.visitantScore;
    var localHits = _snapshot.localHits;
    var visitantHits = _snapshot.visitantHits;

    if (outcome < 54) {
      outs++;
    } else {
      if (_snapshot.esParteLocal) {
        localHits++;
      } else {
        visitantHits++;
      }
      final runs = switch (outcome) {
        < 76 => _single(),
        < 87 => _double(),
        < 94 => _triple(),
        _ => _homeRun(),
      };
      if (_snapshot.esParteLocal) {
        localScore += runs;
      } else {
        visitantScore += runs;
      }
    }

    var inning = _snapshot.inning;
    var esParteLocal = _snapshot.esParteLocal;
    var finalizado = false;
    if (outs >= 3) {
      outs = 0;
      _bases = 0;
      if (esParteLocal) {
        if (inning >= 9 && localScore != visitantScore) {
          finalizado = true;
        } else {
          inning++;
          esParteLocal = false;
        }
      } else if (inning >= 9 && localScore > visitantScore) {
        finalizado = true;
      } else {
        esParteLocal = true;
      }
    }

    _snapshot = StatsSnapshot(
      inning: inning,
      esParteLocal: esParteLocal,
      outsCount: outs,
      localScore: localScore,
      visitantScore: visitantScore,
      localHits: localHits,
      visitantHits: visitantHits,
      finalizado: finalizado,
    );
    notifyListeners();
  }

  int _single() {
    final scored = _bases & 0x4 == 0 ? 0 : 1;
    _bases = ((_bases << 1) & 0x6) | 0x1;
    return scored;
  }

  int _double() {
    final scored = _countBases(0x6);
    _bases = ((_bases & 0x1) << 2) | 0x2;
    return scored;
  }

  int _triple() {
    final scored = _countBases(0x7);
    _bases = 0x4;
    return scored;
  }

  int _homeRun() {
    final scored = _countBases(0x7) + 1;
    _bases = 0;
    return scored;
  }

  int _countBases(int mask) {
    var count = 0;
    for (var bit = 1; bit <= 4; bit <<= 1) {
      if (_bases & bit != 0 && mask & bit != 0) count++;
    }
    return count;
  }

  int _nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % max;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
