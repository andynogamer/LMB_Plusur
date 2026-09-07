import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ar/ar_session_state.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/primary_button.dart';

/// Terminal failure chrome. Always offers the manual team path (Article VI.7).
class ArFailedPanel extends StatelessWidget {
  const ArFailedPanel({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  final ArFailed failure;
  final VoidCallback onRetry;

  static const manualPathLabel = 'Elegir equipo manualmente';

  @override
  Widget build(BuildContext context) {
    final copy = failure.copy;
    final labels = <String>[
      for (final action in copy.acciones)
        if (action != 'Elegir equipo') action,
      manualPathLabel,
    ];

    return Column(
      key: const Key('ar-failed'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          copy.titulo,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          copy.cuerpo,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        for (final label in labels) ...[
          PrimaryButton(
            label: label,
            icon: _iconFor(label),
            onPressed: () => _onAction(context, label),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  void _onAction(BuildContext context, String label) {
    if (label == 'Reintentar') {
      onRetry();
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.teams);
  }

  IconData _iconFor(String label) {
    return switch (label) {
      'Reintentar' => Icons.refresh_rounded,
      'Abrir ajustes' => Icons.settings_rounded,
      'Instalar' => Icons.download_rounded,
      _ => Icons.groups_rounded,
    };
  }
}
