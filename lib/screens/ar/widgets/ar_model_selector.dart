import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

enum ArModelChoice { defaultModel, stadium, player }

class ArModelSelector extends StatelessWidget {
  const ArModelSelector({
    super.key,
    required this.choice,
    required this.onChanged,
  });

  final ArModelChoice choice;
  final ValueChanged<ArModelChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('ar-model-selector'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ModelButton(
          buttonKey: const Key('ar-model-stadium'),
          tooltip: 'Mostrar estadio',
          icon: Icons.stadium_rounded,
          selected: choice == ArModelChoice.stadium,
          onPressed: () => onChanged(ArModelChoice.stadium),
        ),
        const SizedBox(width: 8),
        _ModelButton(
          buttonKey: const Key('ar-model-player'),
          tooltip: 'Mostrar jugador',
          icon: Icons.sports_baseball_rounded,
          selected: choice == ArModelChoice.player,
          onPressed: () => onChanged(ArModelChoice.player),
        ),
      ],
    );
  }
}

class _ModelButton extends StatelessWidget {
  const _ModelButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final Key buttonKey;
  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        key: buttonKey,
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        style: IconButton.styleFrom(
          foregroundColor: selected ? AppColors.black : AppColors.white,
          backgroundColor: selected
              ? AppColors.button
              : AppColors.navyCard.withValues(alpha: 0.9),
          side: BorderSide(
            color: selected
                ? AppColors.button
                : AppColors.button.withValues(alpha: 0.4),
          ),
        ),
        tooltip: tooltip,
      ),
    );
  }
}
