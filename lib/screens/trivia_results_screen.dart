import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';

class TriviaResultsScreen extends StatelessWidget {
  const TriviaResultsScreen({
    super.key,
    required this.puntaje,
  });

  final int puntaje;

  static const int totalPreguntas = 5;

  String get _frase {
    if (puntaje >= 5) {
      return '¡Juego Perfecto! Eres una leyenda del béisbol.';
    }
    if (puntaje >= 3) {
      return '¡Buen brazo! Conoces bien a tu equipo.';
    }
    if (puntaje >= 1) {
      return 'Hit sencillo. Aún puedes mejorar tu porcentaje de bateo.';
    }
    return 'Ponche tirándole. ¡Toca regresar a las ligas menores!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(
        children: [
          const AppHeader(title: 'Resultados'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$puntaje / $totalPreguntas',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 56,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _frase,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppColors.button,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 48),
                  PrimaryButton(
                    label: 'Finalizar',
                    height: 64,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
