import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipo_model.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/image_placeholder.dart';
import '../widgets/screen_background.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.equipo,
  });

  final Equipo equipo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: Column(
          children: [
            AppHeader(
              title: equipo.displayName,
              subtitle: 'Historia del club',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Stack(
                    children: [
                      const ImagePlaceholder(
                        height: 220,
                        icon: Icons.sports_baseball,
                      ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'FUNDADO EN ${equipo.fundacion}',
                            style: GoogleFonts.poppins(
                              color: AppColors.button,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    decoration: BoxDecoration(
                      color: AppColors.navyCard.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.button.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      equipo.historia.trim(),
                      style: GoogleFonts.poppins(
                        color: AppColors.white,
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
