import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ar/ar_session_state.dart';
import '../../../models/equipo_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/primary_button.dart';

/// Bottom chrome per [ArSessionState]. Marker title is [ArLocked] / [ArLost]
/// only. [infoTexto] is shown only while Información is active.
class ArSessionBody extends StatelessWidget {
  const ArSessionBody({
    super.key,
    required this.state,
    required this.equipoHint,
    this.onSimulateNext,
    this.modelNote,
    this.actions,
    this.infoActive = false,
  });

  final ArSessionState state;
  final Equipo? equipoHint;
  final VoidCallback? onSimulateNext;

  /// Spanish copy when the GLB is missing or failed. Null when the model is
  /// placed, or when this is not a real session.
  final String? modelNote;

  /// Action bar. Rendered from [ArLocked] and [ArLost].
  final Widget? actions;

  /// Información action is speaking or spinning. Reveals [Marcador.infoTexto].
  final bool infoActive;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ArPreparing() => const _StatusChip(
          panelKey: Key('ar-preparing'),
          title: 'Preparando la experiencia AR',
          body: 'Comprobando si este dispositivo puede escanear.',
        ),
      ArSearching() => _StatusChip(
          panelKey: const Key('ar-searching'),
          title: hintCopy(equipoHint),
          footer: onSimulateNext == null
              ? null
              : PrimaryButton(
                  label: 'Simular siguiente marcador',
                  icon: Icons.view_in_ar_rounded,
                  height: 48,
                  onPressed: onSimulateNext,
                ),
        ),
      ArCandidate(:final hits, :final needed) => _StatusChip(
          panelKey: const Key('ar-candidate'),
          title: 'Confirmando marcador',
          body: '$hits/$needed',
        ),
      ArLocked(:final marcador) => _LockedPanel(
          marcadorTitulo: marcador.titulo,
          infoTexto: marcador.infoTexto,
          modelNote: modelNote,
          actions: actions,
          infoActive: infoActive,
        ),
      ArLost(:final marcador) => _LockedPanel(
          marcadorTitulo: marcador.titulo,
          infoTexto: marcador.infoTexto,
          modelNote: modelNote,
          actions: actions,
          infoActive: infoActive,
          lostHint: 'Vuelve a apuntar a ${marcador.titulo}.',
        ),
      ArFailed() => const SizedBox.shrink(),
    };
  }

  static String hintCopy(Equipo? hint) {
    if (hint != null) {
      return 'Apunta al logo de ${hint.nombre}';
    }
    return 'Apunta al logo del equipo…';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.panelKey,
    required this.title,
    this.body,
    this.footer,
  });

  final Key panelKey;
  final String title;
  final String? body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: panelKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.3,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: 4),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
        if (footer != null) ...[
          const SizedBox(height: 12),
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
    this.actions,
    this.infoActive = false,
    this.lostHint,
  });

  final String marcadorTitulo;
  final String infoTexto;
  final String? modelNote;
  final Widget? actions;
  final bool infoActive;
  final String? lostHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('ar-locked'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (lostHint != null) ...[
          Text(
            lostHint!,
            key: const Key('ar-lost'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.button,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          marcadorTitulo,
          key: const Key('ar-marker-content'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            height: 1.2,
          ),
        ),
        if (infoActive) ...[
          const SizedBox(height: 8),
          DecoratedBox(
            key: const Key('ar-info-panel'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.button),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                infoTexto,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
        if (actions != null) ...[
          const SizedBox(height: 10),
          actions!,
        ],
        if (modelNote != null) ...[
          const SizedBox(height: 8),
          Text(
            modelNote!,
            key: const Key('ar-model-fallback'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
