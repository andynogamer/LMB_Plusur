import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipo_model.dart';
import '../models/trivia_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/image_placeholder.dart';
import '../widgets/primary_button.dart';

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

  @override
  void initState() {
    super.initState();
    final banco = List<Trivia>.from(widget.equipo.trivias)..shuffle();
    _partida = banco.take(TriviaScreen.preguntasPorPartida).toList();
  }

  Trivia get _actual => _partida[_indice];

  Color _colorOpcion(int index) {
    if (_seleccion == null) return AppColors.button;
    if (index == _actual.respuestaCorrecta) return AppColors.correct;
    if (index == _seleccion) return AppColors.incorrect;
    return AppColors.button;
  }

  Future<void> _responder(int index) async {
    if (_bloqueado) return;

    setState(() {
      _bloqueado = true;
      _seleccion = index;
      if (index == _actual.respuestaCorrecta) {
        _puntaje++;
      }
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final esUltima = _indice >= _partida.length - 1;
    if (esUltima) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.triviaResults,
        arguments: _puntaje,
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
      backgroundColor: AppColors.navy,
      body: Column(
        children: [
          AppHeader(title: widget.equipo.displayName),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
              children: [
                Text(
                  '$progreso/$total',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    width: 180,
                    child: ImagePlaceholder(
                      square: true,
                      icon: Icons.sports_baseball_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _actual.pregunta,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),
                for (var i = 0; i < _actual.opciones.length; i++) ...[
                  PrimaryButton(
                    label: _actual.opciones[i],
                    height: 58,
                    backgroundColor: _colorOpcion(i),
                    onPressed: _bloqueado ? null : () => _responder(i),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
