import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/ar/ar_session_controller.dart';
import 'package:lmb_plusur/ar/ar_session_state.dart';
import 'package:lmb_plusur/ar/ar_tracker.dart';
import 'package:lmb_plusur/ar/marker_registry.dart';
import 'package:lmb_plusur/ar/trackers/fake_ar_tracker.dart';
import 'package:lmb_plusur/models/equipo_model.dart';
import 'package:lmb_plusur/models/marcador_model.dart';
import 'package:vector_math/vector_math_64.dart';

Marcador _marcador(String id) {
  return Marcador(
    id: id,
    equipoId: id,
    tipo: TipoMarcador.estadio,
    titulo: id,
    infoTexto: id,
    markerImage: 'assets/markers/$id.png',
    modelAsset: 'assets/models/$id/modelo.glb',
    anchoMetros: 0.15,
  );
}

ArDetection _detection(String trackerName, {bool tracked = true}) {
  return ArDetection(
    trackerName: trackerName,
    pose: Matrix4.identity(),
    isFullyTracked: tracked,
  );
}

ArReferenceImage _reference(Marcador marcador) {
  return ArReferenceImage(
    name: marcador.id,
    assetPath: marcador.markerImage,
    physicalWidthMeters: marcador.anchoMetros,
  );
}

class _Harness {
  _Harness({
    List<Marcador>? marcadores,
    bool supported = true,
    ArTrackerException? startFailure,
    bool isDemo = false,
    Equipo? hintEquipo,
    DateTime Function()? now,
  })  : tracker = FakeArTracker(supported: supported, startFailure: startFailure),
        registry = MarkerRegistry.fromMarcadores(
          marcadores ??
              [
                _marcador('marcador_estadio_leones'),
                _marcador('marcador_jugador_olmecas'),
                _marcador('marcador_trofeo_piratas'),
              ],
        ) {
    controller = ArSessionController(
      tracker: tracker,
      registry: registry,
      hintEquipo: hintEquipo,
      isDemo: isDemo,
      now: now,
    );
    references = [
      for (final marcador in registry.resolve('marcador_estadio_leones') == null
          ? const <Marcador>[]
          : [
              registry.resolve('marcador_estadio_leones')!,
              registry.resolve('marcador_jugador_olmecas')!,
              registry.resolve('marcador_trofeo_piratas')!,
            ])
        _reference(marcador),
    ];
    if (marcadores != null) {
      references = [
        for (final id in marcadores.map((m) => m.id))
          if (registry.resolve(id) != null) _reference(registry.resolve(id)!),
      ];
    }
  }

  final FakeArTracker tracker;
  final MarkerRegistry registry;
  late final ArSessionController controller;
  late final List<ArReferenceImage> references;

  Future<void> start() => controller.start(references: references);
}

void main() {
  const leones = 'marcador_estadio_leones';
  const olmecas = 'marcador_jugador_olmecas';

  test('detecciones idénticas: ArSearching → ArCandidate → ArLocked', () async {
    final harness = _Harness();
    await harness.start();

    expect(harness.controller.state, isA<ArSearching>());

    harness.tracker.emit(_detection(leones));
    final candidate = harness.controller.state;
    expect(candidate, isA<ArCandidate>());
    expect((candidate as ArCandidate).hits, 1);
    expect(candidate.needed, 2);
    expect(candidate.marcador.id, leones);

    harness.tracker.emit(_detection(leones));
    final locked = harness.controller.state;
    expect(locked, isA<ArLocked>());
    expect((locked as ArLocked).marcador.id, leones);
    expect(locked.isDemo, isFalse);

    await harness.controller.dispose();
  });

  test('un nombre desconocido no sale de ArSearching', () async {
    final harness = _Harness();
    await harness.start();

    harness.tracker.emit(_detection('no_existe'));
    expect(harness.controller.state, isA<ArSearching>());

    harness.tracker.emit(_detection(leones));
    expect(harness.controller.state, isA<ArCandidate>());

    harness.tracker.emit(_detection('no_existe'));
    expect(harness.controller.state, isA<ArSearching>());

    await harness.controller.dispose();
  });

  test('dos marcadores alternados nunca llegan a ArLocked', () async {
    final harness = _Harness();
    await harness.start();

    harness.tracker.emit(_detection(leones));
    expect(harness.controller.state, isA<ArCandidate>());

    harness.tracker.emit(_detection(olmecas));
    expect(harness.controller.state, isA<ArSearching>());

    harness.tracker.emit(_detection(leones));
    expect(harness.controller.state, isA<ArCandidate>());

    harness.tracker.emit(_detection(olmecas));
    expect(harness.controller.state, isA<ArSearching>());
    expect(harness.controller.state, isNot(isA<ArLocked>()));

    await harness.controller.dispose();
  });

  test('ArPreparing no puede pasar a ArLocked', () async {
    final harness = _Harness();
    expect(harness.controller.state, isA<ArPreparing>());

    harness.tracker.emit(_detection(leones));
    harness.tracker.emit(_detection(leones));
    expect(harness.controller.state, isA<ArPreparing>());

    await harness.start();
    expect(harness.controller.state, isA<ArSearching>());
    expect(harness.controller.state, isNot(isA<ArLocked>()));

    await harness.controller.dispose();
  });

  test('cada ArTrackerFailure termina en ArFailed con copia en español', () async {
    const expected = {
      ArTrackerFailure.permissionDenied: 'Cámara sin permiso',
      ArTrackerFailure.arCoreUnavailable: 'Este dispositivo no soporta AR',
      ArTrackerFailure.arCoreNeedsInstall: 'Falta Servicios de Play para AR',
      ArTrackerFailure.databaseBuildFailed: 'No pudimos preparar los marcadores',
      ArTrackerFailure.sessionLost: 'Perdimos el seguimiento',
      ArTrackerFailure.unknown: 'Algo salió mal en AR',
    };

    for (final failure in ArTrackerFailure.values) {
      final harness = _Harness(
        startFailure: ArTrackerException(failure),
      );
      await harness.start();

      final failed = harness.controller.state;
      expect(failed, isA<ArFailed>(), reason: failure.name);
      final arFailed = failed as ArFailed;
      expect(arFailed.failure, failure);
      expect(arFailed.copy.titulo, expected[failure]);
      expect(arFailed.copy.cuerpo, isNotEmpty);
      expect(arFailed.copy.acciones, isNotEmpty);

      await harness.controller.dispose();
    }
  });

  test('un error del stream también se mapea a ArFailed', () async {
    final harness = _Harness();
    await harness.start();

    harness.tracker.fail(ArTrackerFailure.sessionLost);
    expect(harness.controller.state, isA<ArFailed>());
    expect(
      (harness.controller.state as ArFailed).failure,
      ArTrackerFailure.sessionLost,
    );

    await harness.controller.dispose();
  });

  test('dispose cancela la suscripción y llama tracker.stop', () async {
    final harness = _Harness();
    await harness.start();

    await harness.controller.dispose();
    expect(harness.tracker.stopCalled, isTrue);

    harness.tracker.emit(_detection(leones));
    harness.tracker.emit(_detection(leones));
    expect(harness.controller.state, isA<ArSearching>());
  });

  test('fuera de la ventana de 2 s no confirma el mismo marcador', () async {
    var now = DateTime.utc(2026, 9, 7);
    final harness = _Harness(now: () => now);
    await harness.start();

    harness.tracker.emit(_detection(leones));
    expect(harness.controller.state, isA<ArCandidate>());

    now = now.add(const Duration(seconds: 3));
    harness.tracker.emit(_detection(leones));

    final candidate = harness.controller.state;
    expect(candidate, isA<ArCandidate>());
    expect((candidate as ArCandidate).hits, 1);

    await harness.controller.dispose();
  });

  test('el fake recorre todos los marcadores registrados', () async {
    final harness = _Harness();
    await harness.start();

    harness.tracker.emitRegisteredCycle();

    expect(
      harness.tracker.cycledNames,
      [
        'marcador_estadio_leones',
        'marcador_jugador_olmecas',
        'marcador_trofeo_piratas',
      ],
    );
    expect(harness.tracker.cycledNames.toSet(), hasLength(3));

    await harness.controller.dispose();
  });

  test('lib/ar no usa hash, histograma, score ni umbral', () {
    final forbidden = RegExp(
      r'hash|histogram|score|threshold',
      caseSensitive: false,
    );
    final dartFiles = Directory('lib/ar')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    expect(dartFiles, isNotEmpty);
    for (final file in dartFiles) {
      expect(
        forbidden.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: file.path,
      );
    }
  });

  test('ArLocked de demo marca isDemo y conserva la pista del equipo', () async {
    const hint = Equipo(
      id: 'leones_yucatan',
      nombre: 'Leones de Yucatán',
      historia: 'Historia',
      fundacion: 1954,
      trivias: [],
    );
    final harness = _Harness(isDemo: true, hintEquipo: hint);
    await harness.start();

    final searching = harness.controller.state as ArSearching;
    expect(searching.hintEquipo?.id, 'leones_yucatan');

    harness.tracker.emit(_detection(leones));
    harness.tracker.emit(_detection(leones));
    expect((harness.controller.state as ArLocked).isDemo, isTrue);

    await harness.controller.dispose();
  });
}
