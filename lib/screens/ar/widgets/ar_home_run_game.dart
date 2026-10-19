import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

const Duration _basePitchDuration = Duration(milliseconds: 2200);
const Duration _betweenPitches = Duration(milliseconds: 650);
const double _minimumZoneProgress = 0.2;
const double _zoneProgressRange = 0.6;
const double _battingZoneWidth = 38;
const double _pitchBallDiameter = 17;
const double _pitchBallPadding = 8;
const double _pitchBallLayoutWidth = _pitchBallDiameter + _pitchBallPadding * 2;

@visibleForTesting
Duration homeRunPitchDuration(int pitchNumber) {
  assert(pitchNumber > 0);
  final gradualSpeedUp = 1 + (pitchNumber - 1) * 0.025;
  return Duration(
    microseconds: (_basePitchDuration.inMicroseconds / gradualSpeedUp).round(),
  );
}

@visibleForTesting
double homeRunZoneProgress(math.Random random) {
  return _minimumZoneProgress + random.nextDouble() * _zoneProgressRange;
}

@visibleForTesting
bool homeRunIsHit({
  required double ballProgress,
  required double zoneProgress,
  required double laneWidth,
}) {
  final zoneLeft = zoneProgress * math.max(0, laneWidth - _battingZoneWidth);
  final ballCenter =
      ballProgress * math.max(0, laneWidth - _pitchBallLayoutWidth) +
          _pitchBallLayoutWidth / 2;
  final ballRadius = _pitchBallDiameter / 2;
  return ballCenter + ballRadius >= zoneLeft &&
      ballCenter - ballRadius <= zoneLeft + _battingZoneWidth;
}

/// A local endless timing game rendered in Flutter chrome over the AR session.
class ArHomeRunGame extends StatefulWidget {
  const ArHomeRunGame({
    super.key,
    this.bestScore = 0,
    this.onBestScoreChanged,
    this.random,
  });

  final int bestScore;
  final ValueChanged<int>? onBestScoreChanged;

  final math.Random? random;

  @override
  State<ArHomeRunGame> createState() => _ArHomeRunGameState();
}

class _ArHomeRunGameState extends State<ArHomeRunGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pitchMotion = AnimationController(
    vsync: this,
    duration: homeRunPitchDuration(1),
  )..addStatusListener(_onPitchStatus);
  late final math.Random _random = widget.random ?? math.Random();

  Timer? _nextPitch;
  int _pitchNumber = 0;
  int _score = 0;
  late int _bestScore = widget.bestScore;
  double _zoneProgress = 0.5;
  String? _feedback;
  Color _feedbackColor = AppColors.white;
  bool _started = false;
  bool _finished = false;
  bool _swung = false;

  @override
  void didUpdateWidget(covariant ArHomeRunGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bestScore > _bestScore) _bestScore = widget.bestScore;
  }

  void _startGame() {
    setState(() {
      _started = true;
      _finished = false;
      _pitchNumber = 1;
      _score = 0;
      _feedback = null;
    });
    _startPitch();
  }

  void _startPitch() {
    if (!mounted || _finished) return;
    _swung = false;
    _zoneProgress = homeRunZoneProgress(_random);
    _pitchMotion
      ..duration = homeRunPitchDuration(_pitchNumber)
      ..forward(from: 0);
  }

  void _onPitchStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _swung || _finished) return;
    _resolveSwing(hit: false, message: '¡Se fue el lanzamiento!');
  }

  void _swing({required double laneWidth}) {
    if (!_started || _finished || _swung || !_pitchMotion.isAnimating) return;
    final hit = homeRunIsHit(
      ballProgress: _pitchMotion.value,
      zoneProgress: _zoneProgress,
      laneWidth: laneWidth,
    );
    final message = hit
        ? '¡Jonrón! ¡Buen batazo!'
        : _pitchMotion.value < _zoneProgress
            ? '¡Swing antes de tiempo!'
            : '¡Llegaste tarde al lanzamiento!';
    _resolveSwing(hit: hit, message: message);
  }

  void _resolveSwing({required bool hit, required String message}) {
    _swung = true;
    _pitchMotion.stop();
    setState(() {
      _feedback = message;
      _feedbackColor = hit ? AppColors.correct : AppColors.incorrect;
      if (hit) {
        _score++;
        if (_score > _bestScore) {
          _bestScore = _score;
          widget.onBestScoreChanged?.call(_bestScore);
        }
      } else {
        _finished = true;
      }
    });

    if (!hit) return;
    _nextPitch = Timer(_betweenPitches, () {
      if (!mounted) return;
      setState(() {
        _pitchNumber++;
        _feedback = null;
      });
      _startPitch();
    });
  }

  void _replay() {
    _nextPitch?.cancel();
    _pitchMotion
      ..stop()
      ..reset();
    setState(() {
      _pitchNumber = 0;
      _score = 0;
      _feedback = null;
      _started = false;
      _finished = false;
      _swung = false;
    });
  }

  @override
  void dispose() {
    _nextPitch?.cancel();
    _pitchMotion
      ..removeStatusListener(_onPitchStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('ar-home-run-game'),
      decoration: BoxDecoration(
        color: AppColors.navyCard.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.button.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) => _finished
              ? _completion()
              : _round(laneWidth: constraints.maxWidth),
        ),
      ),
    );
  }

  Widget _round({required double laneWidth}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _started ? 'LANZAMIENTO $_pitchNumber' : 'RETO DE JONRÓN',
          key: const Key('ar-home-run-progress'),
          style: GoogleFonts.poppins(
            color: AppColors.button,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        _scoreboard(),
        const SizedBox(height: 8),
        _pitchLane(),
        const SizedBox(height: 6),
        Text(
          _started
              ? 'Toca cuando la pelota cruce la zona de bateo.'
              : 'Batea a tiempo cuando la pelota cruce la zona.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
        if (_feedback case final feedback?) ...[
          const SizedBox(height: 5),
          Text(
            feedback,
            key: const Key('ar-home-run-feedback'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _feedbackColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('ar-home-run-swing'),
            onPressed: !_started
                ? _startGame
                : _swung
                    ? null
                    : () => _swing(laneWidth: laneWidth),
            icon: Icon(
              _started ? Icons.sports_baseball_rounded : Icons.play_arrow,
            ),
            label: Text(_started ? 'BATEAR' : 'EMPEZAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.button,
              foregroundColor: AppColors.black,
              textStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _scoreboard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ScoreLabel(
            label: 'RACHA', value: _score, key: const Key('ar-home-run-score')),
        _ScoreLabel(
          label: 'MEJOR',
          value: _bestScore,
          key: const Key('ar-home-run-best-score'),
        ),
      ],
    );
  }

  Widget _pitchLane() {
    return AnimatedBuilder(
      animation: _pitchMotion,
      builder: (context, _) => SizedBox(
        height: 46,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF183B43), Color(0xFF244D52)],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment(_zoneProgress * 2 - 1, 0),
                  child: Container(
                    key: const Key('ar-home-run-zone'),
                    width: _battingZoneWidth,
                    decoration: BoxDecoration(
                      color: AppColors.correct.withValues(alpha: 0.22),
                      border: Border.symmetric(
                        vertical: BorderSide(
                          color: AppColors.correct.withValues(alpha: 0.8),
                          width: 2,
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.sports_baseball_rounded,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                ),
                if (_started && !_finished)
                  Align(
                    alignment: Alignment(_pitchMotion.value * 2 - 1, 0),
                    child: const Padding(
                      padding: EdgeInsets.all(_pitchBallPadding),
                      child: Icon(
                        Icons.circle,
                        color: AppColors.white,
                        size: _pitchBallDiameter,
                        shadows: [
                          Shadow(color: AppColors.button, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _completion() {
    return Column(
      key: const Key('ar-home-run-complete'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.emoji_events_rounded,
          color: AppColors.button,
          size: 32,
        ),
        const SizedBox(height: 4),
        Text(
          '¡Fin del reto!',
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        Text(
          'Lograste una racha de $_score jonrones.',
          key: const Key('ar-home-run-result'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.button,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        _scoreboard(),
        if (_feedback != null) ...[
          const SizedBox(height: 4),
          Text(
            _feedback!,
            key: const Key('ar-home-run-feedback'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _feedbackColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('ar-home-run-replay'),
            onPressed: _replay,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('INTENTAR DE NUEVO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.button,
              foregroundColor: AppColors.black,
              textStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreLabel extends StatelessWidget {
  const _ScoreLabel({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          '$value',
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
