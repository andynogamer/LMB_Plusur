import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipo_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/feature_card.dart';
import '../widgets/screen_background.dart';

class TeamMenuScreen extends StatelessWidget {
  const TeamMenuScreen({
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
              subtitle: 'Fundado en ${equipo.fundacion}',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.navyCard.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.button.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${equipo.trivias.length} trivias  ·  3 highlights',
                          style: GoogleFonts.poppins(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Elige cómo quieres vivir a ${equipo.nombre}.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FeatureCard(
                    title: 'Historia',
                    subtitle: 'El origen y la identidad del club.',
                    icon: Icons.menu_book_rounded,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.history,
                        arguments: equipo,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  FeatureCard(
                    title: 'Trivia',
                    subtitle: '5 preguntas al azar. Pon a prueba tu fanatismo.',
                    icon: Icons.quiz_rounded,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.trivia,
                        arguments: equipo,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  FeatureCard(
                    title: 'Highlights',
                    subtitle: 'Reproduce los momentos destacados.',
                    icon: Icons.play_circle_fill_rounded,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.highlights,
                        arguments: equipo,
                      );
                    },
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
