import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/trivia_score_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_background.dart';

class TriviaResultsArgs {
  const TriviaResultsArgs({
    required this.puntaje,
    required this.equipoId,
  });

  final int puntaje;
  final String equipoId;
}

class TriviaResultsScreen extends StatefulWidget {
  const TriviaResultsScreen({
    super.key,
    required this.puntaje,
    required this.equipoId,
  });

  final int puntaje;
  final String equipoId;

  static const int totalPreguntas = 5;

  @override
  State<TriviaResultsScreen> createState() => _TriviaResultsScreenState();
}

class _TriviaResultsScreenState extends State<TriviaResultsScreen> {
  @override
  void initState() {
    super.initState();
    TriviaScoreService.instance.guardarUltimoPuntaje(
      equipoId: widget.equipoId,
      puntaje: widget.puntaje,
    );
  }

  String get _frase {
    final puntaje = widget.puntaje;
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
    final puntaje = widget.puntaje;
    final value = puntaje / TriviaResultsScreen.totalPreguntas;

    return Scaffold(
      body: ScreenBackground(
        child: Column(
          children: [
            const AppHeader(title: 'Resultados', subtitle: 'Fin de la partida'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: value),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, animated, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 180,
                                height: 180,
                                child: CircularProgressIndicator(
                                  value: animated,
                                  strokeWidth: 12,
                                  color: AppColors.button,
                                  backgroundColor: AppColors.navyCard,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$puntaje',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 52,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    '/ ${TriviaResultsScreen.totalPreguntas}',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
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
                    const SizedBox(height: 12),
                    Text(
                      'Último puntaje guardado en este dispositivo.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 48),
                    PrimaryButton(
                      label: 'Finalizar',
                      height: 60,
                      icon: Icons.check_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
