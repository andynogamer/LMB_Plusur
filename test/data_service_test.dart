import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/models/equipo_model.dart';
import 'package:lmb_plusur/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DataService carga los 10 equipos de Zona Sur', () async {
    final equipos = await DataService().cargarEquipos();
    expect(equipos, hasLength(10));
    expect(equipos.every((e) => e.nombre.isNotEmpty), isTrue);
    expect(equipos.any((e) => e.id == 'diablos_rojos'), isTrue);
    expect(
      equipos.firstWhere((e) => e.id == 'guerreros_oaxaca').trivias,
      isNotEmpty,
    );
  });

  test('Equipo.fromJson mapea campos españoles', () {
    final equipo = Equipo.fromJson({
      'id': 'demo',
      'nombre': 'Demo FC',
      'historia': 'Historia de prueba',
      'fundacion': 2000,
      'trivias': [
        {
          'id': 1,
          'pregunta': '¿Año?',
          'opciones': ['2000', '2001'],
          'respuestaCorrecta': 0,
        },
      ],
    });

    expect(equipo.id, 'demo');
    expect(equipo.fundacion, 2000);
    expect(equipo.trivias.single.respuestaCorrecta, 0);
  });
}
