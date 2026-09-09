import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

/// Screen-space particle chrome for US-13. Complements the in-scene ball nodes.
///
/// Does not touch the AR session.
class ArBaseballVfx extends StatefulWidget {
  const ArBaseballVfx({
    super.key,
    required this.active,
    this.oneshot = false,
    this.onFinished,
  });

  final bool active;
  final bool oneshot;
  final VoidCallback? onFinished;

  static const Duration duration = Duration(milliseconds: 2800);

  @override
  State<ArBaseballVfx> createState() => _ArBaseballVfxState();
}

class _ArBaseballVfxState extends State<ArBaseballVfx>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Spark> _sparks;
  late final List<_Confetti> _confetti;
  final _rng = math.Random(7);

  @override
  void initState() {
    super.initState();
    _sparks = List.generate(36, (_) => _Spark.random(_rng));
    _confetti = List.generate(22, (_) => _Confetti.random(_rng));
    _controller = AnimationController(
      vsync: this,
      duration: ArBaseballVfx.duration,
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        if (widget.oneshot) {
          widget.onFinished?.call();
        } else if (widget.active) {
          _reshuffle();
          _controller.forward(from: 0);
        }
      });
    if (widget.active) {
      _controller.forward(from: 0);
    }
  }

  void _reshuffle() {
    for (final spark in _sparks) {
      spark.reseed(_rng);
    }
    for (final bit in _confetti) {
      bit.reseed(_rng);
    }
  }

  @override
  void didUpdateWidget(ArBaseballVfx oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _reshuffle();
      _controller.forward(from: 0);
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final fade = t < 0.75 ? 1.0 : (1.0 - (t - 0.75) / 0.25).clamp(0.0, 1.0);
          return Opacity(
            opacity: fade,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _ParticlePainter(
                    progress: Curves.easeOut.transform(t),
                    sparks: _sparks,
                    confetti: _confetti,
                  ),
                ),
                Align(
                  alignment: const Alignment(0, -0.55),
                  child: Transform.scale(
                    scale: 0.85 +
                        0.15 *
                            Curves.elasticOut
                                .transform(t.clamp(0.0, 1.0)),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.button.withValues(alpha: 0.85),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        child: Text(
                          '¡JONRÓN!',
                          key: const Key('ar-vfx-banner'),
                          style: GoogleFonts.poppins(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Spark {
  _Spark({
    required this.angle,
    required this.speed,
    required this.size,
    required this.hue,
  });

  factory _Spark.random(math.Random rng) {
    return _Spark(
      angle: rng.nextDouble() * math.pi * 2,
      speed: 0.35 + rng.nextDouble() * 0.55,
      size: 2.0 + rng.nextDouble() * 3.5,
      hue: rng.nextBool() ? 0.08 : 0.02,
    );
  }

  double angle;
  double speed;
  double size;
  double hue;

  void reseed(math.Random rng) {
    angle = rng.nextDouble() * math.pi * 2;
    speed = 0.35 + rng.nextDouble() * 0.55;
    size = 2.0 + rng.nextDouble() * 3.5;
    hue = rng.nextBool() ? 0.08 : 0.02;
  }
}

class _Confetti {
  _Confetti({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });

  factory _Confetti.random(math.Random rng) {
    const palette = [
      Color(0xFFE53935),
      Color(0xFFFFF3C4),
      Color(0xFFF5F5F0),
      Color(0xFF4CAF50),
    ];
    return _Confetti(
      angle: rng.nextDouble() * math.pi * 2,
      speed: 0.25 + rng.nextDouble() * 0.45,
      size: 3.0 + rng.nextDouble() * 4.0,
      color: palette[rng.nextInt(palette.length)],
    );
  }

  double angle;
  double speed;
  double size;
  Color color;

  void reseed(math.Random rng) {
    angle = rng.nextDouble() * math.pi * 2;
    speed = 0.25 + rng.nextDouble() * 0.45;
    size = 3.0 + rng.nextDouble() * 4.0;
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.progress,
    required this.sparks,
    required this.confetti,
  });

  final double progress;
  final List<_Spark> sparks;
  final List<_Confetti> confetti;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final maxR = size.shortestSide * 0.48;

    final burst = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF3C4).withValues(alpha: 0.5 * (1 - progress * 0.7)),
          const Color(0xFFE53935).withValues(alpha: 0.16 * (1 - progress)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR * (0.2 + 0.8 * progress), burst);

    for (final spark in sparks) {
      final dist = maxR * spark.speed * progress;
      final pos = center +
          Offset(math.cos(spark.angle) * dist, math.sin(spark.angle) * dist);
      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFFF8E1),
          const Color(0xFFFF7043),
          spark.hue,
        )!
            .withValues(alpha: (1.0 - progress * 0.85).clamp(0.0, 1.0));
      canvas.drawCircle(pos, spark.size * (1.1 - progress * 0.6), paint);
    }

    for (final bit in confetti) {
      final dist = maxR * bit.speed * progress;
      final pos = center +
          Offset(
            math.cos(bit.angle) * dist,
            math.sin(bit.angle) * dist + progress * 18,
          );
      final paint = Paint()
        ..color = bit.color.withValues(
          alpha: (1.0 - progress * 0.9).clamp(0.0, 1.0),
        );
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(bit.angle + progress * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: bit.size,
            height: bit.size * 0.45,
          ),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
