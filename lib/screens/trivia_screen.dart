import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipo_model.dart';
import '../models/trivia_model.dart';
import '../routes/app_routes.dart';
import '../services/feedback_service.dart';
import 'trivia_results_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/screen_background.dart';

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({
    super.key,
    required this.equipo,
  });

  final Equipo equipo;

  static const int preguntasPorPartida = 5;

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  late final List<Trivia> _partida;
  int _indice = 0;
  int _puntaje = 0;
  int? _seleccion;
  bool _bloqueado = false;

  static const _letras = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    final banco = List<Trivia>.from(widget.equipo.trivias)..shuffle();
    _partida = banco.take(TriviaScreen.preguntasPorPartida).toList();
  }

  Trivia get _actual => _partida[_indice];

  Color _fondoOpcion(int index) {
    if (_seleccion == null) return AppColors.button;
    if (index == _actual.respuestaCorrecta) return AppColors.correct;
    if (index == _seleccion) return AppColors.incorrect;
    return AppColors.button;
  }

  Future<void> _responder(int index) async {
    if (_bloqueado) return;

    final correcto = index == _actual.respuestaCorrecta;
    setState(() {
      _bloqueado = true;
      _seleccion = index;
      if (correcto) {
        _puntaje++;
      }
    });

    if (correcto) {
      await FeedbackService.instance.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Correcto!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.correct,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 700),
          ),
        );
      }
    } else {
      await FeedbackService.instance.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Incorrecto. Sigue bateando.',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.incorrect,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 700),
          ),
        );
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final esUltima = _indice >= _partida.length - 1;
    if (esUltima) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.triviaResults,
        arguments: TriviaResultsArgs(
          puntaje: _puntaje,
          equipoId: widget.equipo.id,
        ),
      );
      return;
    }

    setState(() {
      _indice++;
      _seleccion = null;
      _bloqueado = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progreso = _indice + 1;
    final total = _partida.length;

    return Scaffold(
      body: ScreenBackground(
        child: Column(
          children: [
            AppHeader(
              title: widget.equipo.displayName,
              subtitle: 'Trivia',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                children: [
                  Row(
                    children: [
                      Text(
                        'Pregunta $progreso de $total',
                        style: GoogleFonts.poppins(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$progreso/$total',
                        style: GoogleFonts.poppins(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progreso / total,
                      minHeight: 7,
                      color: AppColors.button,
                      backgroundColor: AppColors.navyCard,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: BoxDecoration(
                      color: AppColors.navyCard.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.button.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      _actual.pregunta,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  for (var i = 0; i < _actual.opciones.length; i++) ...[
                    _OpcionTile(
                      letra: _letras[i],
                      texto: _actual.opciones[i],
                      background: _fondoOpcion(i),
                      onTap: _bloqueado ? null : () => _responder(i),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionTile extends StatelessWidget {
  const _OpcionTile({
    required this.letra,
    required this.texto,
    required this.background,
    required this.onTap,
  });

  final String letra;
  final String texto;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isNeutral = background == AppColors.button;
    final Color foreground = isNeutral ? AppColors.black : AppColors.white;
    final Color badgeColor = isNeutral ? AppColors.navy : AppColors.white.withValues(alpha: 0.2);
    final Color badgeText = isNeutral ? AppColors.button : AppColors.white;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letra,
                  style: GoogleFonts.poppins(
                    color: badgeText,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  texto,
                  style: GoogleFonts.poppins(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
