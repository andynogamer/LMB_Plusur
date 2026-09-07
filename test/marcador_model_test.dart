import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/models/marcador_model.dart';
import 'package:lmb_plusur/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Marcador.fromJson mapea campos espa?oles y tipo', () {
    final marcador = Marcador.fromJson({
      'id': 'demo',
      'equipoId': 'diablos_rojos',
      'tipo': 'estadio',
      'titulo': 'Demo',
      'infoTexto': 'Texto',
      'markerImage': 'assets/x.png',
      'modelAsset': 'assets/y.glb',
      'videoUrl': null,
      'animaciones': ['idle'],
    });

    expect(marcador.tipo, TipoMarcador.estadio);
    expect(marcador.equipoId, 'diablos_rojos');
    expect(marcador.animaciones, ['idle']);
    expect(marcador.videoUrl, isNull);
  });

  test('DataService carga al menos 3 marcadores distintos', () async {
    final marcadores = await DataService().cargarMarcadores();
    expect(marcadores.length, greaterThanOrEqualTo(3));

    final ids = marcadores.map((m) => m.id).toSet();
    expect(ids, containsAll([
      'marcador_estadio_diablos',
      'marcador_jugador_guerreros',
      'marcador_trofeo_pericos',
    ]));

    expect(
      marcadores.map((m) => m.tipo).toSet(),
      containsAll([
        TipoMarcador.estadio,
        TipoMarcador.jugador,
        TipoMarcador.trofeo,
      ]),
    );
  });

  test('marcadorPorEquipoId resuelve diablos_rojos', () async {
    final marcador =
        await DataService().marcadorPorEquipoId('diablos_rojos');
    expect(marcador, isNotNull);
    expect(marcador!.id, 'marcador_estadio_diablos');
  });
}
