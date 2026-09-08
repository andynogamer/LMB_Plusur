import 'package:flutter/services.dart';

/// Speaks marker copy with the platform TTS engine. Not an AR plugin.
///
/// A missing engine or a failed call must not drop the scan session.
class ArSpeechService {
  ArSpeechService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('mx.lmb.plusur/tts');

  static final ArSpeechService instance = ArSpeechService();

  final MethodChannel _channel;

  /// Tests disable this so the platform channel is never touched.
  bool enabled = true;

  Future<void> speak(String text) async {
    if (!enabled || text.trim().isEmpty) return;
    try {
      await _channel.invokeMethod<bool>('speak', {'text': text});
    } on Object {
      // Device without TTS still keeps the session.
    }
  }

  Future<void> stop() async {
    if (!enabled) return;
    try {
      await _channel.invokeMethod<bool>('stop');
    } on Object {
      // Already gone.
    }
  }
}
