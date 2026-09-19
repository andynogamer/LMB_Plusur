import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/marcador_model.dart';
import '../../../theme/app_colors.dart';

enum ArModelChoice { defaultModel, stadium, player }

class ArModelSelector extends StatelessWidget {
  const ArModelSelector({
    super.key,
    required this.marcador,
    required this.choice,
    required this.onChanged,
  });

  final Marcador marcador;
  final ArModelChoice choice;
  final ValueChanged<ArModelChoice> onChanged;

  String get _clubPath => 'assets/models/${marcador.equipoId}';

  String _assetFor(ArModelChoice value) {
    return switch (value) {
      ArModelChoice.defaultModel => marcador.modelAsset,
      ArModelChoice.stadium => '$_clubPath/estadio.glb',
      ArModelChoice.player => '$_clubPath/jugador.glb',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('ar-model-selector'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'MODELO 3D',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _ModelButton(
                label: 'Estadio',
                icon: Icons.stadium_rounded,
                selected: choice == ArModelChoice.stadium,
                onPressed: () => onChanged(ArModelChoice.stadium),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ModelButton(
                label: 'Jugador',
                icon: Icons.sports_baseball_rounded,
                selected: choice == ArModelChoice.player,
                onPressed: () => onChanged(ArModelChoice.player),
              ),
            ),
          ],
        ),
        if (choice == ArModelChoice.defaultModel)
          Text(
            'Modelo actual: ${_assetFor(choice).split('/').last}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.muted,
              fontSize: 10,
            ),
          ),
      ],
    );
  }
}

class _ModelButton extends StatelessWidget {
  const _ModelButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label.toUpperCase()),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? AppColors.black : AppColors.white,
        backgroundColor: selected ? AppColors.button : Colors.transparent,
        side: BorderSide(
          color: selected
              ? AppColors.button
              : AppColors.button.withValues(alpha: 0.4),
        ),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}
