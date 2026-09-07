import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

/// Mandatory label while the session is the fake tracker (Article VI.6).
class ArDemoBadge extends StatelessWidget {
  const ArDemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.navyCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.button.withValues(alpha: 0.25)),
      ),
      child: Text(
        'MODO DEMO',
        style: GoogleFonts.poppins(
          color: AppColors.button,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
