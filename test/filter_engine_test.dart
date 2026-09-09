import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/services/filter_engine.dart';

void main() {
  test('el motor solo expone las familias permitidas', () {
    final nombres = FiltroPartido.values.map((f) => f.name).toSet();

    expect(nombres, containsAll([
      'desenfoque',
      'pixelado',
      'termica',
      'ajusteColor',
      'suavizado',
      'pasteles',
      'altaSaturacion',
    ]));
    expect(
      nombres.any(
        (name) =>
            name.contains('gris') ||
            name.contains('sepia') ||
            name.contains('expos') ||
            name.contains('invert') ||
            name.contains('gray') ||
            name.contains('bw'),
      ),
      isFalse,
    );
  });

  test('aplicar deja el original intacto y envuelve el resto', () {
    const child = SizedBox(key: Key('clip'));

    expect(FilterEngine.aplicar(FiltroPartido.ninguno, child), same(child));
    expect(
      FilterEngine.aplicar(FiltroPartido.desenfoque, child),
      isA<ImageFiltered>(),
    );
    expect(
      FilterEngine.aplicar(FiltroPartido.termica, child),
      isA<ColorFiltered>(),
    );
    expect(
      FilterEngine.aplicar(FiltroPartido.altaSaturacion, child),
      isA<ColorFiltered>(),
    );
  });

  test('las etiquetas no nombran filtros prohibidos', () {
    final etiquetas = FiltroPartido.values.map(FilterEngine.etiqueta).join(' ');
    final baja = etiquetas.toLowerCase();

    expect(baja.contains('blanco'), isFalse);
    expect(baja.contains('gris'), isFalse);
    expect(baja.contains('sepia'), isFalse);
    expect(baja.contains('expos'), isFalse);
    expect(baja.contains('invert'), isFalse);
  });
}
