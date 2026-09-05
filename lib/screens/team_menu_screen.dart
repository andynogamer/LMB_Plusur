import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipo_model.dart';
import '../routes/app_routes.dart';
import '../services/trivia_score_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/feature_card.dart';
import '../widgets/screen_background.dart';

class TeamMenuScreen extends StatefulWidget {
  const TeamMenuScreen({
    super.key,
    required this.equipo,
  });

  final Equipo equipo;

  @override
  State<TeamMenuScreen> createState() => _TeamMenuScreenState();
}

class _TeamMenuScreenState extends State<TeamMenuScreen> {
  int? _ultimoPuntaje;
  bool _cargandoPuntaje = true;

  Equipo get equipo => widget.equipo;

  @override
  void initState() {
    super.initState();
    _cargarUltimoPuntaje();
  }

  Future<void> _cargarUltimoPuntaje() async {
    final score =
        await TriviaScoreService.instance.obtenerUltimoPuntaje(equipo.id);
    if (!mounted) return;
    setState(() {
      _ultimoPuntaje = score;
      _cargandoPuntaje = false;
    });
  }

  Future<void> _abrirTrivia() async {
    await Navigator.of(context).pushNamed(
      AppRoutes.trivia,
      arguments: equipo,
    );
    await _cargarUltimoPuntaje();
  }

  @override
  Widget build(BuildContext context) {
    final triviaSubtitle = _cargandoPuntaje
        ? '5 preguntas al azar. Pon a prueba tu fanatismo.'
        : _ultimoPuntaje == null
            ? '5 preguntas al azar. Pon a prueba tu fanatismo.'
            : 'Último puntaje: $_ultimoPuntaje / 5';

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
                          _ultimoPuntaje == null
                              ? '${equipo.trivias.length} trivias  ·  3 highlights'
                              : '${equipo.trivias.length} trivias  ·  Último puntaje: $_ultimoPuntaje / 5',
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
                    title: 'Abrir experiencia AR',
                    subtitle: 'Apunta la cámara al logo de este equipo.',
                    icon: Icons.view_in_ar_rounded,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.ar,
                        arguments: equipo,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
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
                    subtitle: triviaSubtitle,
                    icon: Icons.quiz_rounded,
                    onTap: _abrirTrivia,
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
