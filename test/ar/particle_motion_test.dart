import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/ar/ar_tracker.dart';
import 'package:lmb_plusur/ar/particle_motion.dart';

void main() {
  test('all four presets move, grow into view, spin, and fade out', () {
    for (final (index, effect) in ArParticleEffect.values.indexed) {
      final motion = ArParticleMotion.forEffect(
        effect: effect,
        angle: index * math.pi / 3,
        random: math.Random(index),
      );
      final start = motion.positionAt(0);
      final moving = motion.positionAt(0.6);

      expect(
        (moving - start).length,
        greaterThan(0.02),
        reason: '${effect.name} should visibly travel',
      );
      expect(motion.scaleAt(0.6), greaterThan(0));
      expect(motion.yawAt(0.6).abs(), greaterThan(0));
      expect(motion.scaleAt(motion.lifetimeSeconds), 0);
    }
  });

  test('sparks rise quickly and expire before confetti', () {
    final sparks = ArParticleMotion.forEffect(
      effect: ArParticleEffect.chispas,
      angle: 0,
      random: math.Random(12),
    );
    final confetti = ArParticleMotion.forEffect(
      effect: ArParticleEffect.confeti,
      angle: 0,
      random: math.Random(12),
    );

    expect(sparks.positionAt(0.5).y, greaterThan(sparks.start.y));
    expect(sparks.lifetimeSeconds, lessThan(confetti.lifetimeSeconds));
  });

  test('confetti arcs upward then falls while dust expands near the ground',
      () {
    final confetti = ArParticleMotion.forEffect(
      effect: ArParticleEffect.confeti,
      angle: 0,
      random: math.Random(21),
    );
    final dust = ArParticleMotion.forEffect(
      effect: ArParticleEffect.polvoDelDiamante,
      angle: 0,
      random: math.Random(21),
    );

    expect(confetti.positionAt(0.8).y, greaterThan(confetti.start.y));
    expect(
      confetti.positionAt(confetti.lifetimeSeconds).y,
      lessThan(confetti.positionAt(0.8).y),
    );
    final dustStartRadius = math.sqrt(
      dust.start.x * dust.start.x + dust.start.z * dust.start.z,
    );
    final dustEnd = dust.positionAt(1.0);
    final dustEndRadius = math.sqrt(
      dustEnd.x * dustEnd.x + dustEnd.z * dustEnd.z,
    );
    expect(dustEndRadius, greaterThan(dustStartRadius));
    expect(dustEnd.y, greaterThan(dust.start.y));
  });
}
