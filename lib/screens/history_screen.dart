import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipo_model.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/image_placeholder.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.equipo,
  });

  final Equipo equipo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(
        children: [
          AppHeader(title: equipo.displayName),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const ImagePlaceholder(
                  height: 210,
                  icon: Icons.sports_baseball,
                ),
                const SizedBox(height: 20),
                Text(
                  equipo.historia.trim(),
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
