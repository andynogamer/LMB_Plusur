import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart' show Vector3;

import 'ar_tracker.dart';

class ArParticleMotion {
  const ArParticleMotion({
    required this.effect,
    required this.start,
    required this.velocity,
    required this.acceleration,
    required this.spin,
    required this.phase,
    required this.scale,
    required this.lifetimeSeconds,
    required this.wobble,
  });

  final ArParticleEffect effect;
  final Vector3 start;
  final Vector3 velocity;
  final Vector3 acceleration;
  final double spin;
  final double phase;
  final double scale;
  final double lifetimeSeconds;
  final double wobble;

  factory ArParticleMotion.forEffect({
    required ArParticleEffect effect,
    required double angle,
    required math.Random random,
  }) {
    final radial = Vector3(math.cos(angle), 0, math.sin(angle));
    double randomRange(double min, double max) =>
        min + random.nextDouble() * (max - min);
    double randomSigned(double min, double max) =>
        randomRange(min, max) * (random.nextBool() ? 1 : -1);
    final phase = random.nextDouble() * math.pi * 2;

    return switch (effect) {
      ArParticleEffect.jonron => ArParticleMotion(
          effect: effect,
          start: Vector3(radial.x * 0.007, 0.025, radial.z * 0.007),
          velocity: Vector3(
            radial.x * randomRange(0.14, 0.22),
            randomRange(0.16, 0.26),
            radial.z * randomRange(0.14, 0.22),
          ),
          acceleration: Vector3(0, -0.18, 0),
          spin: randomSigned(3.5, 7.0),
          phase: phase,
          scale: 0.62,
          lifetimeSeconds: randomRange(2.25, 2.8),
          wobble: 0.003,
        ),
      ArParticleEffect.chispas => ArParticleMotion(
          effect: effect,
          start: Vector3(radial.x * 0.008, 0.015, radial.z * 0.008),
          velocity: Vector3(
            radial.x * randomRange(0.025, 0.055),
            randomRange(0.24, 0.34),
            radial.z * randomRange(0.025, 0.055),
          ),
          acceleration: Vector3(0, -0.30, 0),
          spin: randomSigned(8, 15),
          phase: phase,
          scale: 0.7,
          lifetimeSeconds: randomRange(1.25, 1.75),
          wobble: 0.002,
        ),
      ArParticleEffect.confeti => ArParticleMotion(
          effect: effect,
          start: Vector3(radial.x * 0.02, 0.04, radial.z * 0.02),
          velocity: Vector3(
            radial.x * randomRange(0.035, 0.075),
            randomRange(0.13, 0.21),
            radial.z * randomRange(0.035, 0.075),
          ),
          acceleration: Vector3(0, -0.16, 0),
          spin: randomSigned(6, 12),
          phase: phase,
          scale: 0.72,
          lifetimeSeconds: randomRange(2.1, 2.8),
          wobble: 0.012,
        ),
      ArParticleEffect.polvoDelDiamante => ArParticleMotion(
          effect: effect,
          start: Vector3(radial.x * 0.01, 0.008, radial.z * 0.01),
          velocity: Vector3(
            radial.x * randomRange(0.055, 0.095),
            randomRange(0.015, 0.04),
            radial.z * randomRange(0.055, 0.095),
          ),
          acceleration: Vector3(0, 0.008, 0),
          spin: randomSigned(0.8, 2.2),
          phase: phase,
          scale: 0.82,
          lifetimeSeconds: randomRange(1.5, 2.1),
          wobble: 0.009,
        ),
    };
  }

  Vector3 positionAt(double elapsedSeconds) {
    final time = elapsedSeconds.clamp(0.0, lifetimeSeconds).toDouble();
    final halfTimeSquared = 0.5 * time * time;
    final position = Vector3(
      start.x + velocity.x * time + acceleration.x * halfTimeSquared,
      start.y + velocity.y * time + acceleration.y * halfTimeSquared,
      start.z + velocity.z * time + acceleration.z * halfTimeSquared,
    );
    if (effect == ArParticleEffect.confeti) {
      position.x += math.sin(time * 5 + phase) * wobble;
      position.z += math.cos(time * 4 + phase) * wobble * 0.7;
    } else if (effect == ArParticleEffect.polvoDelDiamante) {
      position.x += math.sin(time * 2.5 + phase) * wobble;
      position.z += math.cos(time * 2.5 + phase) * wobble;
    }
    return position;
  }

  double scaleAt(double elapsedSeconds) {
    if (elapsedSeconds >= lifetimeSeconds) return 0;
    final age = (elapsedSeconds / lifetimeSeconds).clamp(0.0, 1.0).toDouble();
    final growth = (age / 0.18).clamp(0.0, 1.0).toDouble();
    final fade =
        age < 0.72 ? 1.0 : ((1 - age) / 0.28).clamp(0.0, 1.0).toDouble();
    return scale * (0.45 + 0.55 * growth) * fade;
  }

  double yawAt(double elapsedSeconds) =>
      spin * elapsedSeconds.clamp(0.0, lifetimeSeconds).toDouble();
}
