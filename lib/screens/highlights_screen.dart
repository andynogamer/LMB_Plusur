import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipo_model.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/video_placeholder.dart';

class HighlightsScreen extends StatelessWidget {
  const HighlightsScreen({
    super.key,
    required this.equipo,
  });

  final Equipo equipo;

  static const List<String> _placeholders = [
    'HOME RUN!!!',
    'SAFE!!!',
    'PONCHE CLAVE',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(
        children: [
          AppHeader(title: equipo.displayName),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: _placeholders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 28),
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Text(
                      _placeholders[index],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const VideoPlaceholder(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
