import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipo_model.dart';
import '../routes/app_routes.dart';
import '../services/data_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/primary_button.dart';

/// Ruta reservada para `flutter_unity_widget`.
/// Hoy simula la detección de un logo y muestra el overlay de Flutter.
class ArViewScreen extends StatefulWidget {
  const ArViewScreen({super.key});

  @override
  State<ArViewScreen> createState() => _ArViewScreenState();
}

class _ArViewScreenState extends State<ArViewScreen> {
  Equipo? _detectedTeam;
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _detectionTimer = Timer(const Duration(seconds: 2), _simularDeteccion);
  }

  Future<void> _simularDeteccion() async {
    final equipos = await DataService().cargarEquipos();
    if (!mounted) return;

    Equipo? guerreros;
    for (final equipo in equipos) {
      if (equipo.id == 'guerreros_oaxaca') {
        guerreros = equipo;
        break;
      }
    }

    setState(() {
      _detectedTeam = guerreros ?? (equipos.isNotEmpty ? equipos.first : null);
    });
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const _SimulatedUnityView(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  const AppLogo(size: 52),
                ],
              ),
            ),
          ),
          if (_detectedTeam == null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Text(
                  'APUNTA AL LOGO DEL EQUIPO…',
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.bottomCenter,
              child: _ArTeamOverlay(equipo: _detectedTeam!),
            ),
        ],
      ),
    );
  }
}

/// Sustituir por `UnityWidget` cuando el export de Unity esté listo.
class _SimulatedUnityView extends StatelessWidget {
  const _SimulatedUnityView();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1C2048),
            Color(0xFF0B0D1F),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.view_in_ar,
          color: Color(0x66FFFFFF),
          size: 96,
        ),
      ),
    );
  }
}

class _ArTeamOverlay extends StatelessWidget {
  const _ArTeamOverlay({required this.equipo});

  final Equipo equipo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              equipo.displayName,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Historia',
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.history,
                  arguments: equipo,
                );
              },
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Trivia',
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.trivia,
                  arguments: equipo,
                );
              },
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Highlights',
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.highlights,
                  arguments: equipo,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
