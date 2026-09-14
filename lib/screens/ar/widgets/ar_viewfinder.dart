import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Center reticle for [ArSearching] / [ArCandidate]. Does not cover the
/// camera with a filled card — only corner brackets.
class ArViewfinder extends StatelessWidget {
  const ArViewfinder({
    super.key,
    this.confirming = false,
  });

  /// Brighter corners while the debounce gate is counting hits.
  final bool confirming;

  @override
  Widget build(BuildContext context) {
    final color = confirming
        ? AppColors.button
        : AppColors.button.withValues(alpha: 0.7);
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          key: const Key('ar-viewfinder'),
          width: 228,
          height: 228,
          child: CustomPaint(
            painter: _ViewfinderPainter(color: color),
          ),
        ),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const arm = 28.0;
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, arm)
      ..lineTo(0, 0)
      ..lineTo(arm, 0)
      ..moveTo(w - arm, 0)
      ..lineTo(w, 0)
      ..lineTo(w, arm)
      ..moveTo(w, h - arm)
      ..lineTo(w, h)
      ..lineTo(w - arm, h)
      ..moveTo(arm, h)
      ..lineTo(0, h)
      ..lineTo(0, h - arm);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
