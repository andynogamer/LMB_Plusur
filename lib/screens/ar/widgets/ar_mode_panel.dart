import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/equipo_model.dart';
import '../../../models/marcador_model.dart';
import '../../../models/trivia_model.dart';
import '../../../theme/app_colors.dart';
import 'ar_home_run_game.dart';

enum ArExperienceMode { gallery, trivia, homeRun }

const _preguntasTriviaAr = 5;

bool hasFiveDistinctTriviaQuestions(Marcador marcador, Equipo? equipo) {
  if (equipo == null || equipo.id != marcador.equipoId) return false;
  final ids = <int>{};
  final preguntas = <String>{};
  for (final trivia in equipo.trivias) {
    final pregunta = trivia.pregunta.trim().toLowerCase();
    if (ids.add(trivia.id)) preguntas.add(pregunta);
  }
  return preguntas.length >= _preguntasTriviaAr;
}

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
    this.triviaRandom,
  });

  final Marcador marcador;
  final Equipo? equipo;
  final ArExperienceMode mode;
  final ValueChanged<ArExperienceMode> onModeChanged;
  final int bestHomeRunScore;
  final ValueChanged<int>? onBestHomeRunScoreChanged;
  final math.Random? homeRunRandom;
  final math.Random? triviaRandom;

  @override
  State<ArModePanel> createState() => _ArModePanelState();
}

class _ArModePanelState extends State<ArModePanel> {
  late int _bestHomeRunScore;
  late List<Trivia> _triviaQuestions;
  int _triviaIndex = 0;
  int _triviaScore = 0;
  int? _triviaSelection;
  bool _triviaFinished = false;

  void _recordBestHomeRunScore(int score) {
    if (score <= _bestHomeRunScore) return;
    setState(() => _bestHomeRunScore = score);
    widget.onBestHomeRunScoreChanged?.call(score);
  }

  void _resetTriviaRound() {
    final equipo = widget.equipo;
    if (!hasFiveDistinctTriviaQuestions(widget.marcador, equipo)) {
      _triviaQuestions = const [];
    } else {
      final ids = <int>{};
      final preguntas = <String>{};
      final distinct = equipo!.trivias.where((trivia) {
        final pregunta = trivia.pregunta.trim().toLowerCase();
        return ids.add(trivia.id) && preguntas.add(pregunta);
      }).toList();
      distinct.shuffle(widget.triviaRandom);
      _triviaQuestions = distinct.take(_preguntasTriviaAr).toList();
    }
    _triviaIndex = 0;
    _triviaScore = 0;
    _triviaSelection = null;
    _triviaFinished = false;
  }

  void _answerTrivia(int answerIndex) {
    if (_triviaSelection != null || _triviaFinished) return;
    setState(() {
      _triviaSelection = answerIndex;
      if (answerIndex == _triviaQuestions[_triviaIndex].respuestaCorrecta) {
        _triviaScore++;
      }
    });
  }

  void _advanceTrivia() {
    if (_triviaSelection == null || _triviaFinished) return;
    setState(() {
      if (_triviaIndex == _triviaQuestions.length - 1) {
        _triviaFinished = true;
      } else {
        _triviaIndex++;
        _triviaSelection = null;
      }
    });
  }

  void _replayTrivia() {
    setState(_resetTriviaRound);
  }

  @override
  void initState() {
    super.initState();
    _bestHomeRunScore = widget.bestHomeRunScore;
    _resetTriviaRound();
  }

  @override
  void didUpdateWidget(covariant ArModePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bestHomeRunScore > _bestHomeRunScore) {
      _bestHomeRunScore = widget.bestHomeRunScore;
    }
    if (oldWidget.mode != widget.mode &&
        widget.mode == ArExperienceMode.trivia) {
      _resetTriviaRound();
    }
    if (oldWidget.marcador.id != widget.marcador.id ||
        oldWidget.marcador.equipoId != widget.marcador.equipoId ||
        oldWidget.equipo?.id != widget.equipo?.id ||
        oldWidget.equipo?.trivias != widget.equipo?.trivias) {
      _resetTriviaRound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final triviaDisponible = hasFiveDistinctTriviaQuestions(
      widget.marcador,
      widget.equipo,
    );
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
            if (triviaDisponible) ...[
              const SizedBox(width: 6),
              Expanded(
                child: _ModeButton(
                  buttonKey: const Key('ar-mode-trivia'),
                  label: 'Trivia AR',
                  icon: Icons.quiz_rounded,
                  selected: widget.mode == ArExperienceMode.trivia,
                  onPressed: () =>
                      widget.onModeChanged(ArExperienceMode.trivia),
                ),
              ),
            ],
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
        if (!triviaDisponible && widget.mode == ArExperienceMode.gallery) ...[
          const SizedBox(height: 8),
          const _ModeMessage(
            key: Key('ar-trivia-unavailable'),
            text:
                'Trivia AR no disponible: este equipo necesita cinco preguntas distintas.',
          ),
        ],
        if (widget.mode == ArExperienceMode.trivia) ...[
          const SizedBox(height: 10),
          _TriviaOverlay(
            equipo: widget.equipo,
            available: triviaDisponible,
            questions: _triviaQuestions,
            index: _triviaIndex,
            score: _triviaScore,
            selected: _triviaSelection,
            finished: _triviaFinished,
            onAnswer: _answerTrivia,
            onContinue: _advanceTrivia,
            onReplay: _replayTrivia,
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
    required this.available,
    required this.questions,
    required this.index,
    required this.score,
    required this.selected,
    required this.finished,
    required this.onAnswer,
    required this.onContinue,
    required this.onReplay,
  });

  final Equipo? equipo;
  final bool available;
  final List<Trivia> questions;
  final int index;
  final int score;
  final int? selected;
  final bool finished;
  final ValueChanged<int> onAnswer;
  final VoidCallback onContinue;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    if (!available || questions.length != _preguntasTriviaAr) {
      return const _ModeMessage(
        key: Key('ar-trivia-unavailable'),
        text:
            'Trivia AR no disponible: este equipo necesita cinco preguntas distintas.',
      );
    }
    if (finished) {
      return _triviaCard(
        children: [
          Text(
            '¡Trivia completada!',
            key: const Key('ar-trivia-finished'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.button,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Puntaje final: $score/$_preguntasTriviaAr',
            key: const Key('ar-trivia-final-score'),
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('ar-trivia-replay'),
            onPressed: onReplay,
            child: Text(
              'JUGAR OTRA VEZ',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    }
    final trivia = questions[index];
    return DecoratedBox(
      key: const Key('ar-trivia'),
      decoration: _triviaDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 4),
            Text(
              'Pregunta ${index + 1} de $_preguntasTriviaAr  ·  Aciertos: $score',
              key: const Key('ar-trivia-progress'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (index + 1) / _preguntasTriviaAr,
                minHeight: 5,
                color: AppColors.button,
                backgroundColor: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              trivia.pregunta,
              key: const Key('ar-trivia-question'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            for (var option = 0; option < trivia.opciones.length; option++)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: Key('ar-trivia-answer-$option'),
                    onPressed: selected == null ? () => onAnswer(option) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: BorderSide(
                        color: _optionColor(option, trivia, selected),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      trivia.opciones[option],
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
                selected == trivia.respuestaCorrecta
                    ? '¡Correcto!'
                    : 'Incorrecto. Respuesta correcta: '
                        '${trivia.opciones[trivia.respuestaCorrecta]}',
                key: const Key('ar-trivia-answer-feedback'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: selected == trivia.respuestaCorrecta
                      ? AppColors.correct
                      : AppColors.incorrect,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              OutlinedButton(
                key: const Key('ar-trivia-next'),
                onPressed: onContinue,
                child: Text(
                  index == _preguntasTriviaAr - 1
                      ? 'VER RESULTADO'
                      : 'SIGUIENTE PREGUNTA',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
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

BoxDecoration _triviaDecoration() => BoxDecoration(
      color: AppColors.navyCard.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.button.withValues(alpha: 0.3)),
    );

Widget _triviaCard({required List<Widget> children}) {
  return DecoratedBox(
    key: const Key('ar-trivia-finish'),
    decoration: _triviaDecoration(),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    ),
  );
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
  const _ModeMessage({super.key, required this.text});

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
