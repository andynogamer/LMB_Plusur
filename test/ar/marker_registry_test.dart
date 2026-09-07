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

  test('ar_markers.json carga 3 marcadores tipados', () async {
    final marcadores = await DataService().cargarMarcadores();

    expect(marcadores, hasLength(3));
    expect(
      marcadores.map((m) => m.id).toSet(),
      {
        'marcador_estadio_leones',
        'marcador_jugador_olmecas',
        'marcador_trofeo_piratas',
      },
    );
    expect(
      marcadores.map((m) => m.tipo).toSet(),
      {TipoMarcador.estadio, TipoMarcador.jugador, TipoMarcador.trofeo},
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
