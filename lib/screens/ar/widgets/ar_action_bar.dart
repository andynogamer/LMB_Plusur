import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

/// Clip names written by `tools/write_lowpoly_glbs.py`. Do not invent others.
const String kClipIdle = 'idle';
const String kClipGesto = 'gesto';

/// Matches the `gesto` clip length in that generator. Native returns to idle
/// on its own; this only releases the pressed state.
const Duration kGestoClipLength = Duration(milliseconds: 2400);

/// Spanish copy when the locked model has no `gesto` clip. Session stays up.
const String kGestoMissingCopy = 'Este modelo no tiene animación de gesto.';

/// Spanish copy when Filament refused the clip. Session stays up.
const String kGestoFailedCopy =
    'No pudimos reproducir el gesto. El escaneo sigue activo.';

/// Two action types, reachable only from [ArLocked].
class ArActionBar extends StatelessWidget {
  const ArActionBar({
    super.key,
    required this.gestoPressed,
    required this.infoPressed,
    required this.onGesto,
    required this.onInfo,
    this.note,
  });

  final bool gestoPressed;
  final bool infoPressed;
  final VoidCallback onGesto;
  final VoidCallback onInfo;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('ar-actions'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                buttonKey: const Key('ar-action-gesto'),
                label: gestoPressed ? 'Reposo' : 'Gesto',
                icon: Icons.sports_baseball_rounded,
                selected: gestoPressed,
                onPressed: onGesto,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                buttonKey: const Key('ar-action-info'),
                label: 'Información',
                icon: Icons.record_voice_over_rounded,
                selected: infoPressed,
                onPressed: onInfo,
              ),
            ),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: 8),
          Text(
            note!,
            key: const Key('ar-action-note'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.buttonKey,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.button : AppColors.navyCard;
    final foreground = selected ? AppColors.black : AppColors.white;
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        key: buttonKey,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected
                  ? AppColors.button
                  : AppColors.button.withValues(alpha: 0.35),
              width: selected ? 2 : 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
