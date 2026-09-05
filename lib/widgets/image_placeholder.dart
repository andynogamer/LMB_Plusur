import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    this.height = 200,
    this.icon = Icons.sports_baseball,
    this.square = false,
  });

  final double height;
  final IconData icon;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final child = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navyCard,
            AppColors.imagePlaceholder,
          ],
        ),
      ),
      child: Center(
        child: Icon(icon, color: AppColors.button.withValues(alpha: 0.85), size: 64),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: square
          ? AspectRatio(aspectRatio: 1, child: child)
          : SizedBox(width: double.infinity, height: height, child: child),
    );
  }
}
