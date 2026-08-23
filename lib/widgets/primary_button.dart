import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 56,
    this.backgroundColor = AppColors.button,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final Color foreground = backgroundColor == AppColors.button
        ? AppColors.black
        : AppColors.white;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foreground,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: foreground,
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
