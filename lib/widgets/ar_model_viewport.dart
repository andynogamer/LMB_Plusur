import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../models/marcador_model.dart';
import '../theme/app_colors.dart';

/// Style-matched 3D stage for a detected [Marcador] (US-07).
class ArModelViewport extends StatelessWidget {
  const ArModelViewport({
    super.key,
    required this.marcador,
  });

  final Marcador marcador;

  IconData get _tipoIcon {
    switch (marcador.tipo) {
      case TipoMarcador.estadio:
        return Icons.stadium_rounded;
      case TipoMarcador.trofeo:
        return Icons.emoji_events_rounded;
      case TipoMarcador.pelota:
        return Icons.sports_baseball_rounded;
      case TipoMarcador.jugador:
        return Icons.accessibility_new_rounded;
    }
  }

  bool get _useModelViewer {
    if (kIsWeb) return true;
    // Widget tests have no WebView platform implementation.
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      decoration: BoxDecoration(
        color: AppColors.navyCard.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.button.withValues(alpha: 0.14),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_useModelViewer)
            ModelViewer(
              key: ValueKey(marcador.modelAsset),
              src: marcador.modelAsset,
              alt: marcador.titulo,
              backgroundColor: const Color(0x0014183B),
              autoRotate: true,
              cameraControls: true,
              disableZoom: false,
              ar: false,
            )
          else
            _PlaceholderStage(icon: _tipoIcon, titulo: marcador.titulo),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: AppColors.button.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_tipoIcon, color: AppColors.button, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'MODELO 3D ? ${marcador.tipo.name.toUpperCase()}',
                    style: GoogleFonts.poppins(
                      color: AppColors.button,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderStage extends StatelessWidget {
  const _PlaceholderStage({
    required this.icon,
    required this.titulo,
  });

  final IconData icon;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.navyElevated,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.button.withValues(alpha: 0.85), size: 72),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
