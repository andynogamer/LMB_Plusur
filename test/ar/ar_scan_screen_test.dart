import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/ar/ar_tracker.dart';
import 'package:lmb_plusur/ar/marker_registry.dart';
import 'package:lmb_plusur/ar/trackers/fake_ar_tracker.dart';
import 'package:lmb_plusur/models/equipo_model.dart';
import 'package:lmb_plusur/models/marcador_model.dart';
import 'package:lmb_plusur/routes/app_routes.dart';
import 'package:lmb_plusur/screens/ar/ar_scan_screen.dart';
import 'package:lmb_plusur/screens/ar/widgets/ar_action_bar.dart';
import 'package:lmb_plusur/screens/ar/widgets/ar_failed_panel.dart';
import 'package:lmb_plusur/services/ar_speech_service.dart';
import 'package:lmb_plusur/services/feedback_service.dart';

Marcador _marcador({
  required String id,
  required String titulo,
  required String infoTexto,
  TipoMarcador tipo = TipoMarcador.estadio,
  List<String> animaciones = const [],
}) {
  return Marcador(
    id: id,
    equipoId: 'leones_yucatan',
    tipo: tipo,
    titulo: titulo,
    infoTexto: infoTexto,
    markerImage: 'assets/markers/$id.png',
    modelAsset: 'assets/models/$id/modelo.glb',
    anchoMetros: 0.15,
    animaciones: animaciones,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const titulo = 'Parque Kukulcán Alamo';
  const info = 'Casa de los Leones de Yucatán en Mérida.';
  late Marcador leones;
  late MarkerRegistry registry;

  setUp(() {
    FeedbackService.instance.enabled = false;
    ArSpeechService.instance.enabled = false;
    leones = _marcador(id: 'marcador_estadio_leones', titulo: titulo, infoTexto: info);
    registry = MarkerRegistry.fromMarcadores([leones]);
  });

  Future<void> pumpScan(
    WidgetTester tester, {
    required FakeArTracker tracker,
    Equipo? hint,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.teams: (_) => const Scaffold(body: Text('lista-equipos')),
        },
        home: ArScanScreen(
          equipoHint: hint,
          tracker: tracker,
          registry: registry,
          marcadores: [leones],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('el contenido del marcador solo aparece en ArLocked', (tester) async {
    final tracker = FakeArTracker();
    await pumpScan(tester, tracker: tracker);

    expect(find.byKey(const Key('ar-searching')), findsOneWidget);
    expect(find.text('Apunta al logo del equipo…'.toUpperCase()), findsOneWidget);
    expect(find.byKey(const Key('ar-marker-content')), findsNothing);
    expect(find.text(info), findsNothing);

    tracker.emit(
      ArDetection(
        trackerName: leones.id,
        pose: Matrix4.identity(),
        isFullyTracked: true,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('ar-searching')), findsNothing);
    expect(find.byKey(const Key('ar-candidate')), findsOneWidget);
    expect(find.textContaining('1/2'), findsOneWidget);
    expect(find.byKey(const Key('ar-marker-content')), findsNothing);
    expect(find.text(info), findsNothing);

    tracker.emit(
      ArDetection(
        trackerName: leones.id,
        pose: Matrix4.identity(),
        isFullyTracked: true,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('ar-locked')), findsOneWidget);
    expect(find.byKey(const Key('ar-marker-content')), findsOneWidget);
    expect(find.text(titulo), findsOneWidget);
    expect(find.text(info), findsOneWidget);
    expect(find.text('MODO DEMO'), findsOneWidget);
  });

  testWidgets('conserva la pista D-11 del equipo', (tester) async {
    final tracker = FakeArTracker();
    await pumpScan(
      tester,
      tracker: tracker,
      hint: const Equipo(
        id: 'leones_yucatan',
        nombre: 'Leones de Yucatán',
        historia: 'Historia',
        fundacion: 1954,
        trivias: [],
      ),
    );

    expect(
      find.text('Apunta al logo de Leones de Yucatán'.toUpperCase()),
      findsOneWidget,
    );
  });

  testWidgets('cada fallo muestra su copia y la salida manual', (tester) async {
    const expected = {
      ArTrackerFailure.permissionDenied: (
        'Cámara sin permiso',
        'Necesitamos la cámara para escanear los marcadores.',
      ),
      ArTrackerFailure.arCoreUnavailable: (
        'Este dispositivo no soporta AR',
        'Puedes explorar los equipos y videos sin escanear.',
      ),
      ArTrackerFailure.arCoreNeedsInstall: (
        'Falta Servicios de Play para AR',
        'Instálalo para usar la experiencia AR.',
      ),
      ArTrackerFailure.databaseBuildFailed: (
        'No pudimos preparar los marcadores',
        'Vuelve a intentarlo.',
      ),
      ArTrackerFailure.sessionLost: (
        'Perdimos el seguimiento',
        'Apunta de nuevo al marcador.',
      ),
      ArTrackerFailure.unknown: (
        'Algo salió mal en AR',
        'Puedes reintentar o elegir tu equipo.',
      ),
    };

    for (final failure in ArTrackerFailure.values) {
      await tester.pumpWidget(const SizedBox.shrink());
      final tracker = FakeArTracker(startFailure: ArTrackerException(failure));
      await pumpScan(tester, tracker: tracker);

      expect(find.byKey(const Key('ar-failed')), findsOneWidget, reason: failure.name);
      expect(find.text(expected[failure]!.$1), findsOneWidget);
      expect(find.text(expected[failure]!.$2), findsOneWidget);
      expect(find.text(ArFailedPanel.manualPathLabel.toUpperCase()), findsOneWidget);
      expect(find.byKey(const Key('ar-marker-content')), findsNothing);
    }

    await tester.tap(find.text(ArFailedPanel.manualPathLabel.toUpperCase()));
    await tester.pumpAndSettle();
    expect(find.text('lista-equipos'), findsOneWidget);
  });

  testWidgets('las acciones solo existen en ArLocked', (tester) async {
    final tracker = FakeArTracker();
    await pumpScan(tester, tracker: tracker);

    expect(find.byKey(const Key('ar-actions')), findsNothing);
    expect(find.byKey(const Key('ar-action-gesto')), findsNothing);
    expect(find.byKey(const Key('ar-action-info')), findsNothing);

    tracker.emit(
      ArDetection(
        trackerName: leones.id,
        pose: Matrix4.identity(),
        isFullyTracked: true,
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('ar-actions')), findsNothing);

    tracker.emit(
      ArDetection(
        trackerName: leones.id,
        pose: Matrix4.identity(),
        isFullyTracked: true,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('ar-locked')), findsOneWidget);
    expect(find.byKey(const Key('ar-actions')), findsOneWidget);
    expect(find.text(info), findsOneWidget);

    await tester.tap(find.byKey(const Key('ar-action-gesto')));
    await tester.pump();
    expect(find.byKey(const Key('ar-action-note')), findsOneWidget);
    expect(find.text(kGestoMissingCopy), findsOneWidget);
    expect(tracker.playedClips, isEmpty);

    await tester.tap(find.byKey(const Key('ar-action-info')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tracker.presentationYaw, greaterThan(0));
    expect(find.byKey(const Key('ar-info-panel')), findsOneWidget);

    tracker.emit(
      ArDetection(
        trackerName: leones.id,
        pose: Matrix4.identity(),
        isFullyTracked: false,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('ar-lost')), findsOneWidget);
    expect(find.byKey(const Key('ar-actions')), findsNothing);
    expect(find.byKey(const Key('ar-marker-content')), findsNothing);
  });

  testWidgets('gesto pide el clip del marcador y reposo vuelve a idle', (tester) async {
    final player = _marcador(
      id: 'marcador_jugador_olmecas',
      titulo: 'El legado olmeca',
      infoTexto: 'Los Olmecas de Tabasco honran a la civilización olmeca.',
      tipo: TipoMarcador.jugador,
      animaciones: const [kClipIdle, kClipGesto],
    );
    final tracker = FakeArTracker();
    await tester.pumpWidget(
      MaterialApp(
        home: ArScanScreen(
          tracker: tracker,
          registry: MarkerRegistry.fromMarcadores([player]),
          marcadores: [player],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('ar-actions')), findsNothing);

    tracker.emit(
      ArDetection(
        trackerName: player.id,
        pose: Matrix4.identity(),
        isFullyTracked: true,
      ),
    );
    tracker.emit(
      ArDetection(
        trackerName: player.id,
        pose: Matrix4.identity(),
        isFullyTracked: true,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      tracker.playedClips,
      contains(
        (trackerName: player.id, clipName: kClipIdle, loop: true),
      ),
    );

    await tester.tap(find.byKey(const Key('ar-action-gesto')));
    await tester.pump();
    await tester.pump();

    expect(find.text('REPOSO'), findsOneWidget);
    expect(
      tracker.playedClips.last,
      (trackerName: player.id, clipName: kClipGesto, loop: false),
    );

    await tester.tap(find.byKey(const Key('ar-action-gesto')));
    await tester.pump();
    await tester.pump();

    expect(find.text('GESTO'), findsOneWidget);
    expect(
      tracker.playedClips.last,
      (trackerName: player.id, clipName: kClipIdle, loop: true),
    );
  });
}
