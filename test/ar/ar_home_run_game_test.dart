import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/screens/ar/widgets/ar_home_run_game.dart';

class _SequenceRandom implements math.Random {
  _SequenceRandom(this.values);

  final List<double> values;
  int _index = 0;

  @override
  double nextDouble() => values[_index++ % values.length];

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

void main() {
  test('un toque en el borde visible de la zona también cuenta', () {
    const laneWidth = 336.0;
    const zoneProgress = 0.5;
    const ballLayoutWidth = 33.0;
    const ballRadius = 8.5;
    const zoneWidth = 38.0;
    final zoneLeft = zoneProgress * (laneWidth - zoneWidth);
    final leftTouchProgress = (zoneLeft - ballRadius - ballLayoutWidth / 2) /
        (laneWidth - ballLayoutWidth);
    final rightTouchProgress =
        (zoneLeft + zoneWidth + ballRadius - ballLayoutWidth / 2) /
            (laneWidth - ballLayoutWidth);

    expect(
      homeRunIsHit(
        ballProgress: leftTouchProgress,
        zoneProgress: zoneProgress,
        laneWidth: laneWidth,
      ),
      isTrue,
    );
    expect(
      homeRunIsHit(
        ballProgress: rightTouchProgress,
        zoneProgress: zoneProgress,
        laneWidth: laneWidth,
      ),
      isTrue,
    );
    expect(
      homeRunIsHit(
        ballProgress: leftTouchProgress - 1 / (laneWidth - ballLayoutWidth),
        zoneProgress: zoneProgress,
        laneWidth: laneWidth,
      ),
      isFalse,
    );
    expect(
      homeRunIsHit(
        ballProgress: rightTouchProgress + 1 / (laneWidth - ballLayoutWidth),
        zoneProgress: zoneProgress,
        laneWidth: laneWidth,
      ),
      isFalse,
    );
  });

  Future<void> pumpGame(
    WidgetTester tester, {
    math.Random? random,
    ValueChanged<int>? onBestScoreChanged,
    int bestScore = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: ArHomeRunGame(
                random: random,
                bestScore: bestScore,
                onBestScoreChanged: onBestScoreChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> startGame(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('ar-home-run-swing')));
    await tester.pump();
  }

  Future<void> hitPitch(
    WidgetTester tester,
    int pitchNumber, {
    double zoneProgress = 0.5,
  }) async {
    final hitProgress = zoneProgress;
    final hitTime = Duration(
      milliseconds:
          (homeRunPitchDuration(pitchNumber).inMilliseconds * hitProgress)
              .round(),
    );
    await tester.pump(hitTime);
    await tester.tap(find.byKey(const Key('ar-home-run-swing')));
    await tester.pump();
  }

  test('each pitch gets slightly faster and zones are randomized', () {
    final durations = [
      for (var pitch = 1; pitch <= 20; pitch++)
        homeRunPitchDuration(pitch).inMicroseconds,
    ];
    expect(durations.first, 2200000);
    for (var index = 1; index < durations.length; index++) {
      expect(durations[index], lessThan(durations[index - 1]));
      expect(durations[index - 1] - durations[index], lessThan(60000));
    }

    final random = _SequenceRandom([0.1, 0.9]);
    final firstZone = homeRunZoneProgress(random);
    final secondZone = homeRunZoneProgress(random);
    expect(firstZone, closeTo(0.26, 0.0001));
    expect(secondZone, closeTo(0.74, 0.0001));
    expect(firstZone, isNot(secondZone));
  });

  testWidgets('racha infinita acumula puntos y conserva el mejor resultado', (
    tester,
  ) async {
    var reportedBestScore = 0;
    await pumpGame(
      tester,
      random: _SequenceRandom([0.5]),
      onBestScoreChanged: (score) => reportedBestScore = score,
    );
    await startGame(tester);

    const hitsToProveEndless = 10;
    for (var pitch = 1; pitch <= hitsToProveEndless; pitch++) {
      await hitPitch(tester, pitch);
      expect(
        find.text('¡Jonrón! ¡Buen batazo!'),
        findsOneWidget,
        reason: 'pitch $pitch should land inside the timing window',
      );
      expect(reportedBestScore, pitch);
      await tester.pump(const Duration(milliseconds: 650));
    }

    expect(find.text('LANZAMIENTO 11'), findsOneWidget);
    expect(_scoreValue(tester, 'ar-home-run-score'), '10');
    expect(_scoreValue(tester, 'ar-home-run-best-score'), '10');

    await tester.tap(find.byKey(const Key('ar-home-run-swing')));
    await tester.pump();
    expect(find.byKey(const Key('ar-home-run-complete')), findsOneWidget);
    expect(find.text('Lograste una racha de 10 jonrones.'), findsOneWidget);
    expect(find.text('¡Swing antes de tiempo!'), findsOneWidget);
    expect(_scoreValue(tester, 'ar-home-run-best-score'), '10');
  });

  testWidgets('la zona de bateo cambia en cada lanzamiento', (tester) async {
    await pumpGame(tester, random: _SequenceRandom([0.1, 0.9]));
    await startGame(tester);

    final firstZoneX =
        tester.getCenter(find.byKey(const Key('ar-home-run-zone'))).dx;
    await hitPitch(tester, 1, zoneProgress: 0.26);
    await tester.pump(const Duration(milliseconds: 650));
    final secondZoneX =
        tester.getCenter(find.byKey(const Key('ar-home-run-zone'))).dx;

    expect(firstZoneX, isNot(secondZoneX));
  });

  testWidgets('un lanzamiento sin swing termina y permite replay', (
    tester,
  ) async {
    await pumpGame(tester, random: _SequenceRandom([0.5]));
    await startGame(tester);
    await tester.pump(
      homeRunPitchDuration(1) + const Duration(milliseconds: 1),
    );

    expect(find.byKey(const Key('ar-home-run-complete')), findsOneWidget);
    expect(find.text('¡Se fue el lanzamiento!'), findsOneWidget);
    expect(_scoreValue(tester, 'ar-home-run-best-score'), '0');

    await tester.tap(find.byKey(const Key('ar-home-run-replay')));
    await tester.pump();

    expect(find.byKey(const Key('ar-home-run-complete')), findsNothing);
    expect(find.text('RETO DE JONRÓN'), findsOneWidget);
    expect(_scoreValue(tester, 'ar-home-run-best-score'), '0');
  });
}

String _scoreValue(WidgetTester tester, String key) {
  final value = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(Text),
  );
  return tester.widgetList<Text>(value).last.data!;
}
