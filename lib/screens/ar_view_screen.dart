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

/// Pantalla AR (Flutter-native). Hoy usa detección simulada etiquetada como
/// modo demo hasta SP-01 / US-06.
class ArViewScreen extends StatefulWidget {
  const ArViewScreen({
    super.key,
    this.equipoHint,
  });

  /// Equipo sugerido al llegar desde el menú del club (D-11).
  final Equipo? equipoHint;

  @override
  State<ArViewScreen> createState() => _ArViewScreenState();
}

class _ArViewScreenState extends State<ArViewScreen>
    with SingleTickerProviderStateMixin {
  Equipo? _detectedTeam;
  bool _demoMode = false;
  Timer? _detectionTimer;
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    // Detección simulada — siempre etiquetada como demo (US-02 / Known debt).
    _detectionTimer = Timer(const Duration(seconds: 2), _simularDeteccionDemo);
  }

  Future<void> _simularDeteccionDemo() async {
    final hint = widget.equipoHint;
    if (hint != null) {
      if (!mounted) return;
      setState(() {
        _detectedTeam = hint;
        _demoMode = true;
      });
      return;
    }

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
      _demoMode = true;
    });
  }

  String get _scanHintCopy {
    final hint = widget.equipoHint;
    if (hint != null) {
      return 'Apunta al logo de ${hint.nombre}';
    }
    return 'Apunta al logo del equipo…';
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
          const _SimulatedArView(),
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
                  if (_demoMode || _detectedTeam == null)
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navyCard.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: AppColors.button.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'MODO DEMO',
                        style: GoogleFonts.poppins(
                          color: AppColors.button,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
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
                      _scanHintCopy.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Simulación hasta el reconocimiento real.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.bottomCenter,
              child: _ArTeamOverlay(
                equipo: _detectedTeam!,
                demoMode: _demoMode,
              ),
            ),
        ],
      ),
    );
  }
}

class _SimulatedArView extends StatelessWidget {
  const _SimulatedArView();

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
  const _ArTeamOverlay({
    required this.equipo,
    required this.demoMode,
  });

  final Equipo equipo;
  final bool demoMode;

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
                if (demoMode) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Detección simulada (modo demo)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
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
