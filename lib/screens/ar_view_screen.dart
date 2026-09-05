import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipo_model.dart';
import '../routes/app_routes.dart';
import '../services/data_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/feature_card.dart';

/// Ruta reservada para `flutter_unity_widget`.
/// Hoy simula la detección de un logo y muestra el overlay de Flutter.
class ArViewScreen extends StatefulWidget {
  const ArViewScreen({super.key});

  @override
  State<ArViewScreen> createState() => _ArViewScreenState();
}

class _ArViewScreenState extends State<ArViewScreen>
    with SingleTickerProviderStateMixin {
  Equipo? _detectedTeam;
  Timer? _detectionTimer;
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const _SimulatedUnityView(),
          if (_detectedTeam == null)
            IgnorePointer(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.15, end: 0.55).animate(
                  CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
                ),
                child: const ColoredBox(color: Color(0x3314183B)),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.navy.withValues(alpha: 0.55),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.button.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const AppLogo(size: 46),
                  ),
                ],
              ),
            ),
          ),
          if (_detectedTeam == null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.center_focus_strong_rounded,
                      color: AppColors.button,
                      size: 36,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'APUNTA AL LOGO DEL EQUIPO…',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          color: AppColors.navy.withValues(alpha: 0.88),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.button.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  equipo.displayName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 16),
                FeatureCard(
                  title: 'Historia',
                  subtitle: 'Conoce el origen del equipo.',
                  icon: Icons.menu_book_rounded,
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.history,
                      arguments: equipo,
                    );
                  },
                ),
                const SizedBox(height: 10),
                FeatureCard(
                  title: 'Trivia',
                  subtitle: '5 preguntas al azar.',
                  icon: Icons.quiz_rounded,
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.trivia,
                      arguments: equipo,
                    );
                  },
                ),
                const SizedBox(height: 10),
                FeatureCard(
                  title: 'Highlights',
                  subtitle: 'Reproduce los momentos clave.',
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
        ),
      ),
    );
  }
}
