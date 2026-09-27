import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ar/ar_tracker.dart';
import '../../../theme/app_colors.dart';

/// Clip names written by `tools/write_lowpoly_glbs.py`. Do not invent others.
const String kClipIdle = 'idle';
const String kClipGesto = 'gesto';
const String kClipCelebracion = 'celebracion';

/// Matches the `celebracion` clip length in that generator.
const Duration kCelebracionClipLength = Duration(milliseconds: 2800);

/// Spanish copy when the locked model has no `celebracion` clip.
const String kCelebracionMissingCopy =
    'Este modelo no tiene animación de celebración.';

/// Spanish copy when Filament refused the clip. Session stays up.
const String kCelebracionFailedCopy =
    'No pudimos reproducir la celebración. El escaneo sigue activo.';

class ArActionBar extends StatelessWidget {
  const ArActionBar({
    super.key,
    required this.gestoPressed,
    required this.infoPressed,
    required this.animationPaused,
    required this.activeEffect,
    required this.onGesto,
    required this.onInfo,
    required this.onToggleAnimationPause,
    required this.onCapturePhoto,
    required this.onEffectSelected,
    this.infoEnabled = true,
    this.showCelebracion = true,
    this.showAnimationControl = false,
    this.showPhotoCapture = true,
    this.note,
  });

  final bool gestoPressed;
  final bool infoPressed;
  final bool animationPaused;
  final ArParticleEffect? activeEffect;
  final VoidCallback onGesto;
  final VoidCallback onInfo;
  final VoidCallback onToggleAnimationPause;
  final VoidCallback onCapturePhoto;
  final ValueChanged<ArParticleEffect> onEffectSelected;
  final bool infoEnabled;
  final bool showCelebracion;
  final bool showAnimationControl;
  final bool showPhotoCapture;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final info = _ActionButton(
      buttonKey: const Key('ar-action-info'),
      label: 'Información',
      icon: Icons.record_voice_over_rounded,
      selected: infoPressed,
      onPressed: infoEnabled ? onInfo : null,
    );

    return Column(
      key: const Key('ar-actions'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (showCelebracion) ...[
              Expanded(
                child: _ActionButton(
                  buttonKey: const Key('ar-action-gesto'),
                  label: gestoPressed ? 'Reposo' : 'Celebración',
                  icon: Icons.sports_baseball_rounded,
                  selected: gestoPressed,
                  onPressed: onGesto,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(child: info),
          ],
        ),
        if (showAnimationControl) ...[
          const SizedBox(height: 8),
          _ActionButton(
            buttonKey: const Key('ar-action-animation-pause'),
            label: animationPaused ? 'Reanudar animación' : 'Pausar animación',
            icon: animationPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            selected: animationPaused,
            onPressed: onToggleAnimationPause,
          ),
        ],
        if (showPhotoCapture) ...[
          const SizedBox(height: 8),
          _ActionButton(
            buttonKey: const Key('ar-action-photo'),
            label: 'Tomar foto',
            icon: Icons.photo_camera_rounded,
            selected: false,
            onPressed: onCapturePhoto,
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'EFECTOS DEL DIAMANTE',
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: ListView(
            key: const Key('ar-effect-selector'),
            scrollDirection: Axis.horizontal,
            children: [
              for (final effect in ArParticleEffect.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _EffectButton(
                    effect: effect,
                    selected: activeEffect == effect,
                    onPressed: () => onEffectSelected(effect),
                  ),
                ),
            ],
          ),
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

class _EffectButton extends StatelessWidget {
  const _EffectButton({
    required this.effect,
    required this.selected,
    required this.onPressed,
  });

  final ArParticleEffect effect;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (effect) {
      ArParticleEffect.jonron => ('Jonrón', Icons.sports_baseball_rounded),
      ArParticleEffect.chispas => ('Chispas', Icons.auto_awesome_rounded),
      ArParticleEffect.confeti => ('Confeti', Icons.celebration_rounded),
      ArParticleEffect.polvoDelDiamante => ('Polvo', Icons.grain_rounded),
    };
    final background = selected ? AppColors.button : AppColors.navyCard;
    final foreground = selected ? AppColors.black : AppColors.white;
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        key: Key('ar-effect-${effect.name}'),
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label.toUpperCase()),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected
                  ? AppColors.button
                  : AppColors.button.withValues(alpha: 0.35),
            ),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
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
  final VoidCallback? onPressed;

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
