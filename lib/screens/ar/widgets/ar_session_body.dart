import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ar/ar_session_state.dart';
import '../../../models/equipo_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/primary_button.dart';

/// One panel per [ArSessionState]. Marker content is rendered only in [ArLocked].
class ArSessionBody extends StatelessWidget {
  const ArSessionBody({
    super.key,
    required this.state,
    required this.equipoHint,
    this.onSimulateNext,
    this.modelNote,
    this.onExit,
  });

  final ArSessionState state;
  final Equipo? equipoHint;
  final VoidCallback? onSimulateNext;

  /// Spanish copy when the GLB is missing or failed. Null when the model is
  /// placed, or when this is not a real session.
  final String? modelNote;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ArPreparing() => const _StatusPanel(
          panelKey: Key('ar-preparing'),
          icon: Icons.hourglass_top_rounded,
          title: 'Preparando la experiencia AR',
          body: 'Comprobando si este dispositivo puede escanear.',
        ),
      ArSearching() => _StatusPanel(
          panelKey: const Key('ar-searching'),
          icon: Icons.center_focus_strong_rounded,
          title: _hintCopy(equipoHint),
          body: 'Busca un marcador registrado. Nada se confirma sin un escaneo.',
          footer: onSimulateNext == null
              ? null
              : PrimaryButton(
                  label: 'Simular siguiente marcador',
                  icon: Icons.view_in_ar_rounded,
                  onPressed: onSimulateNext,
                ),
        ),
      ArCandidate(:final hits, :final needed) => _StatusPanel(
          panelKey: const Key('ar-candidate'),
          icon: Icons.center_focus_weak_rounded,
          title: 'Confirmando marcador',
          body: 'Progreso del escaneo: $hits/$needed',
        ),
      ArLocked(:final marcador) => _LockedPanel(
          marcadorTitulo: marcador.titulo,
          infoTexto: marcador.infoTexto,
          modelNote: modelNote,
          onExit: onExit,
        ),
      ArLost(:final marcador) => _StatusPanel(
          panelKey: const Key('ar-lost'),
          icon: Icons.gps_off_rounded,
          title: 'Marcador fuera de cuadro',
          body: 'Vuelve a apuntar a ${marcador.titulo}.',
        ),
      ArFailed() => const SizedBox.shrink(),
    };
  }

  static String _hintCopy(Equipo? hint) {
    if (hint != null) {
      return 'Apunta al logo de ${hint.nombre}';
    }
    return 'Apunta al logo del equipo…';
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.panelKey,
    required this.icon,
    required this.title,
    required this.body,
    this.footer,
  });

  final Key panelKey;
  final IconData icon;
  final String title;
  final String body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: panelKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.button, size: 36),
        const SizedBox(height: 10),
        Text(
          title.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: 16),
          footer!,
        ],
      ],
    );
  }
}

class _LockedPanel extends StatelessWidget {
  const _LockedPanel({
    required this.marcadorTitulo,
    required this.infoTexto,
    this.modelNote,
    this.onExit,
  });

  final String marcadorTitulo;
  final String infoTexto;
  final String? modelNote;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('ar-locked'),
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
          marcadorTitulo,
          key: const Key('ar-marker-content'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          infoTexto,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 1.35,
          ),
        ),
        if (modelNote != null) ...[
          const SizedBox(height: 10),
          Text(
            modelNote!,
            key: const Key('ar-model-fallback'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
        if (onExit != null) ...[
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Salir',
            icon: Icons.close_rounded,
            onPressed: onExit,
          ),
        ],
      ],
    );
  }
}
