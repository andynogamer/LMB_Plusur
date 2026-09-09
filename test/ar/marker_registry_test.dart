import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/ar/marker_registry.dart';
import 'package:lmb_plusur/models/marcador_model.dart';
import 'package:lmb_plusur/services/data_service.dart';

/// Filename stem of an asset path. Lives in the test so production resolution
/// never inspects the path — the tracker reports the stem, and [MarkerRegistry]
/// looks that string up exactly.
String _markerImageStem(String markerImage) {
  final fileName = markerImage.split(RegExp(r'[\\/]')).last;
  final dot = fileName.lastIndexOf('.');
  return dot == -1 ? fileName : fileName.substring(0, dot);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ar_markers.json carga los logos que puntúan al menos 75', () async {
    final marcadores = await DataService().cargarMarcadores();

    expect(marcadores, hasLength(10));
    expect(
      marcadores.map((m) => m.id).toSet(),
      {
        'marcador_estadio_leones',
        'marcador_jugador_olmecas',
        'marcador_trofeo_piratas',
        'marcador_pelota_bravos',
        'marcador_jugador_tigres',
        'marcador_estadio_diablos',
        'marcador_jugador_guerreros',
        'marcador_estadio_conspiradores',
        'marcador_estadio_aguila',
        'marcador_estadio_pericos',
      },
    );
    expect(
      marcadores.map((m) => m.equipoId).toSet(),
      {
        'leones_yucatan',
        'olmecas_tabasco',
        'piratas_campeche',
        'bravos_leon',
        'tigres_quintana_roo',
        'diablos_rojos',
        'guerreros_oaxaca',
        'conspiradores_queretaro',
        'aguila_veracruz',
        'pericos_puebla',
      },
    );
  });

  test('markerImage stem equals marcador id for every entry', () async {
    final marcadores = await DataService().cargarMarcadores();

    expect(marcadores, isNotEmpty);
    for (final marcador in marcadores) {
      expect(_markerImageStem(marcador.markerImage), marcador.id);
    }
  });

  test('resolve devuelve null para un nombre no registrado', () async {
    final marcadores = await DataService().cargarMarcadores();
    final registry = MarkerRegistry.fromMarcadores(marcadores);

    expect(registry.resolve('no_existe'), isNull);
    expect(
      registry.resolve('marcador_estadio_leones')?.equipoId,
      'leones_yucatan',
    );
  });
}
