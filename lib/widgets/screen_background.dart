import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ScreenBackground extends StatelessWidget {
  const ScreenBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.7, -0.85),
          radius: 1.35,
          colors: [
            Color(0xFF2A3168),
            AppColors.navy,
          ],
        ),
      ),
      child: child,
    );
  }
}
