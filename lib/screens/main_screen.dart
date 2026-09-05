import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/feature_card.dart';
import '../widgets/screen_background.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ScreenBackground(
        child: Column(
          children: [
            AppHeader(showBack: false),
            Expanded(child: _MainBody()),
          ],
        ),
      ),
    );
  }
}

class _MainBody extends StatelessWidget {
  const _MainBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIGA MEXICANA',
            style: GoogleFonts.poppins(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 2.2,
            ),
          ),
          Text(
            'Zona Sur',
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 40,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explora la historia, juega trivia y revive los highlights de tu equipo.',
            style: GoogleFonts.poppins(
              color: AppColors.muted,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const Spacer(),
          FeatureCard(
            title: 'Escanear Logo',
            subtitle: 'Apunta la cámara al logo y abre la experiencia AR.',
            icon: Icons.view_in_ar_rounded,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.ar),
          ),
          const SizedBox(height: 14),
          FeatureCard(
            title: 'Seleccionar Equipo',
            subtitle: 'Elige manualmente un club de la Zona Sur.',
            icon: Icons.sports_baseball_rounded,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.teams),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
