import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lmb_plusur/services/data_service.dart';
import 'package:lmb_plusur/services/logo_matcher_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cada marcador de grading se reconoce por su imagen', () async {
    final marcadores = await DataService().cargarMarcadores();
    expect(marcadores.length, greaterThanOrEqualTo(3));

    final matcher = LogoMatcherService();
    await matcher.loadMarcadores(marcadores);
    expect(matcher.marcadorCatalogSize, greaterThanOrEqualTo(3));

    for (final marcador in marcadores) {
      final id = await matcher.matchMarcadorAsset(marcador.markerImage);
      expect(id, marcador.id, reason: 'Failed to recognize ${marcador.id}');
    }
  });

  test('imagen desconocida no fuerza un marcador', () async {
    final marcadores = await DataService().cargarMarcadores();
    final matcher = LogoMatcherService();
    await matcher.loadMarcadores(marcadores);

    final noise = img.Image(width: 64, height: 64);
    img.fill(noise, color: img.ColorRgb8(20, 180, 90));
    final bytes = Uint8List.fromList(img.encodePng(noise));

    final id = await matcher.matchMarcadorBytes(
      bytes,
      maxHammingDistance: 8,
    );
    expect(id, isNull);
  });
}
