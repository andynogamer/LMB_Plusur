import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/equipo_model.dart';
import '../../../models/marcador_model.dart';
import '../../../models/trivia_model.dart';
import '../../../theme/app_colors.dart';
import 'ar_home_run_game.dart';

enum ArExperienceMode { gallery, trivia, homeRun }

class ArModePanel extends StatefulWidget {
  const ArModePanel({
    super.key,
    required this.marcador,
    required this.equipo,
    required this.mode,
    required this.onModeChanged,
    this.bestHomeRunScore = 0,
    this.onBestHomeRunScoreChanged,
    this.homeRunRandom,
  });

  final Marcador marcador;
  final Equipo? equipo;
  final ArExperienceMode mode;
  final ValueChanged<ArExperienceMode> onModeChanged;
  final int bestHomeRunScore;
  final ValueChanged<int>? onBestHomeRunScoreChanged;
  final math.Random? homeRunRandom;

  @override
  State<ArModePanel> createState() => _ArModePanelState();
}

class _ArModePanelState extends State<ArModePanel> {
  int? _selected;
  late int _bestHomeRunScore;

  void _recordBestHomeRunScore(int score) {
    if (score <= _bestHomeRunScore) return;
    setState(() => _bestHomeRunScore = score);
    widget.onBestHomeRunScoreChanged?.call(score);
  }

  @override
  void initState() {
    super.initState();
    _bestHomeRunScore = widget.bestHomeRunScore;
  }

  @override
  void didUpdateWidget(covariant ArModePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bestHomeRunScore > _bestHomeRunScore) {
      _bestHomeRunScore = widget.bestHomeRunScore;
    }
    if (oldWidget.mode != widget.mode) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final trivia = widget.equipo?.trivias.firstOrNull;
    return Column(
      key: const Key('ar-modes'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _ModeButton(
                buttonKey: const Key('ar-mode-gallery'),
                label: 'Galería AR',
                icon: Icons.view_in_ar_rounded,
                selected: widget.mode == ArExperienceMode.gallery,
                onPressed: () => widget.onModeChanged(ArExperienceMode.gallery),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ModeButton(
                buttonKey: const Key('ar-mode-trivia'),
                label: 'Trivia AR',
                icon: Icons.quiz_rounded,
                selected: widget.mode == ArExperienceMode.trivia,
                onPressed: () => widget.onModeChanged(ArExperienceMode.trivia),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ModeButton(
                buttonKey: const Key('ar-mode-home-run'),
                label: 'Jonrón',
                icon: Icons.sports_baseball_rounded,
                selected: widget.mode == ArExperienceMode.homeRun,
                onPressed: () => widget.onModeChanged(ArExperienceMode.homeRun),
              ),
            ),
          ],
        ),
        if (widget.mode == ArExperienceMode.trivia) ...[
          const SizedBox(height: 10),
          _TriviaOverlay(
            equipo: widget.equipo,
            trivia: trivia,
            selected: _selected,
            onSelected: (index) => setState(() => _selected = index),
          ),
        ],
        if (widget.mode == ArExperienceMode.homeRun) ...[
          const SizedBox(height: 10),
          ArHomeRunGame(
            bestScore: _bestHomeRunScore,
            onBestScoreChanged: _recordBestHomeRunScore,
            random: widget.homeRunRandom,
          ),
        ],
      ],
    );
  }
}

class _TriviaOverlay extends StatelessWidget {
  const _TriviaOverlay({
    required this.equipo,
    required this.trivia,
    required this.selected,
    required this.onSelected,
  });

  final Equipo? equipo;
  final Trivia? trivia;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (equipo == null || trivia == null) {
      return const _ModeMessage(
        text: 'No hay una trivia vinculada a este marcador.',
      );
    }
    return DecoratedBox(
      key: const Key('ar-trivia'),
      decoration: BoxDecoration(
        color: AppColors.navyCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.button.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              'RETO DE ${equipo!.nombre.toUpperCase()}',
              style: GoogleFonts.poppins(
                color: AppColors.button,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              trivia!.pregunta,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < trivia!.opciones.length; index++)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed:
                        selected == null ? () => onSelected(index) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: BorderSide(
                        color: _optionColor(index, trivia!, selected),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      trivia!.opciones[index],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                  ),
                ),
              ),
            if (selected != null) ...[
              const SizedBox(height: 6),
              Text(
                selected == trivia!.respuestaCorrecta
                    ? '¡Correcto!'
                    : 'Sigue bateando. La respuesta correcta está marcada.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: selected == trivia!.respuestaCorrecta
                      ? AppColors.correct
                      : AppColors.incorrect,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _optionColor(int index, Trivia trivia, int? selected) {
    if (selected == null) return AppColors.button.withValues(alpha: 0.5);
    if (index == trivia.respuestaCorrecta) return AppColors.correct;
    if (index == selected) return AppColors.incorrect;
    return AppColors.muted.withValues(alpha: 0.35);
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    this.buttonKey,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final Key? buttonKey;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: buttonKey,
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label.toUpperCase()),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? AppColors.black : AppColors.white,
        backgroundColor: selected ? AppColors.button : Colors.transparent,
        side: BorderSide(
          color: selected
              ? AppColors.button
              : AppColors.button.withValues(alpha: 0.4),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _ModeMessage extends StatelessWidget {
  const _ModeMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      key: const Key('ar-mode-message'),
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        color: AppColors.muted,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
    );
  }
}
