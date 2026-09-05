import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/feedback_service.dart';
import '../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 56,
    this.backgroundColor = AppColors.button,
    this.icon,
    this.playFeedback = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Color backgroundColor;
  final IconData? icon;
  final bool playFeedback;

  @override
  Widget build(BuildContext context) {
    final Color foreground = backgroundColor == AppColors.button
        ? AppColors.black
        : AppColors.white;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed == null
            ? null
            : () {
                if (playFeedback) {
                  FeedbackService.instance.tap();
                }
                onPressed!();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foreground,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foreground,
          elevation: 0,
          shadowColor: Colors.transparent,
          overlayColor: AppColors.navy.withValues(alpha: 0.16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: foreground),
              const SizedBox(width: 10),
            ],
            Flexible(
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
          ],
        ),
      ),
    );
  }
}
