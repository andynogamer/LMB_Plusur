import 'package:shared_preferences/shared_preferences.dart';

/// Persists only the last trivia score per team (D-08 / US-03). No accounts.
class TriviaScoreService {
  TriviaScoreService._();
  static final TriviaScoreService instance = TriviaScoreService._();

  static String _key(String equipoId) => 'trivia_last_score_$equipoId';

  Future<void> guardarUltimoPuntaje({
    required String equipoId,
    required int puntaje,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(equipoId), puntaje);
  }

  Future<int?> obtenerUltimoPuntaje(String equipoId) async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_key(equipoId))) return null;
    return prefs.getInt(_key(equipoId));
  }
}
