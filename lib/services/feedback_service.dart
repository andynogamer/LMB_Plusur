import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum FeedbackTone { tap, success, error }

/// Short SFX + haptics for user actions (US-04 / professor feedback requirement).
class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  AudioPlayer? _player;
  DateTime? _lastTapAt;
  static const _tapDebounce = Duration(milliseconds: 120);

  /// Allows tests to disable audio I/O.
  bool enabled = true;

  AudioPlayer get _audio {
    return _player ??= AudioPlayer();
  }

  Future<void> play(
    FeedbackTone tone, {
    bool haptic = true,
  }) async {
    if (!enabled) return;

    if (tone == FeedbackTone.tap) {
      final now = DateTime.now();
      if (_lastTapAt != null && now.difference(_lastTapAt!) < _tapDebounce) {
        return;
      }
      _lastTapAt = now;
    }

    if (haptic) {
      switch (tone) {
        case FeedbackTone.tap:
          await HapticFeedback.selectionClick();
        case FeedbackTone.success:
          await HapticFeedback.lightImpact();
        case FeedbackTone.error:
          await HapticFeedback.mediumImpact();
      }
    }

    final asset = switch (tone) {
      FeedbackTone.tap => 'sfx/tap.wav',
      FeedbackTone.success => 'sfx/success.wav',
      FeedbackTone.error => 'sfx/error.wav',
    };

    try {
      await _audio.stop();
      await _audio.play(AssetSource(asset));
    } catch (error, stack) {
      debugPrint('FeedbackService play failed: $error\n$stack');
    }
  }

  Future<void> tap() => play(FeedbackTone.tap);
  Future<void> success() => play(FeedbackTone.success);
  Future<void> error() => play(FeedbackTone.error);

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }
}
