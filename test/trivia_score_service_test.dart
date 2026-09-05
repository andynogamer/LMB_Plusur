import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/services/trivia_score_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('guarda y lee el último puntaje por equipo', () async {
    final service = TriviaScoreService.instance;

    expect(await service.obtenerUltimoPuntaje('diablos_rojos'), isNull);

    await service.guardarUltimoPuntaje(equipoId: 'diablos_rojos', puntaje: 4);
    expect(await service.obtenerUltimoPuntaje('diablos_rojos'), 4);

    await service.guardarUltimoPuntaje(equipoId: 'diablos_rojos', puntaje: 2);
    expect(await service.obtenerUltimoPuntaje('diablos_rojos'), 2);

    expect(await service.obtenerUltimoPuntaje('pericos_puebla'), isNull);
  });
}
