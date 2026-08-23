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
    final child = ColoredBox(
      color: AppColors.imagePlaceholder,
      child: Center(
        child: Icon(icon, color: AppColors.white, size: 64),
      ),
    );

    if (square) {
      return AspectRatio(aspectRatio: 1, child: child);
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: child,
    );
  }
}
