import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/app_routes.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/screen_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootAndGo());
    });
  }

  /// Warm logo decode + Poppins, then leave. No fixed 3 s idle wait.
  Future<void> _bootAndGo() async {
    if (!mounted) return;
    final warm = Future.wait<void>([
      precacheImage(const AssetImage(AppAssets.logo), context),
      GoogleFonts.pendingFonts([GoogleFonts.poppins()]),
    ]);
    await Future.wait<void>([
      warm,
      Future<void>.delayed(const Duration(milliseconds: 1100)),
    ]);
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacementNamed(AppRoutes.main);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.button.withValues(alpha: 0.18),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const AppLogo(size: 176),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'CARGANDO',
                    style: GoogleFonts.poppins(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(99)),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppColors.button,
                        backgroundColor: AppColors.navyCard,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
