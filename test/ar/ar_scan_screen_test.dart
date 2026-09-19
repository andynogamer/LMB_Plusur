import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/ar/ar_tracker.dart';
import 'package:lmb_plusur/ar/marker_registry.dart';
import 'package:lmb_plusur/ar/ar_session_state.dart';
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
    leones = _marcador(
      id: 'marcador_estadio_leones',
      titulo: titulo,
      infoTexto: info,
    );
    registry = MarkerRegistry.fromMarcadores([leones]);
  });

  Future<void> pumpScan(
    WidgetTester tester, {
    required FakeArTracker tracker,
    Equipo? hint,
    Marcador? marcador,
    MarkerRegistry? registryOverride,
  }) async {
    final target = marcador ?? leones;
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.teams: (_) => const Scaffold(body: Text('lista-equipos')),
        },
        home: ArScanScreen(
          equipoHint: hint,
          tracker: tracker,
          registry: registryOverride ??
              (marcador == null
                  ? registry
                  : MarkerRegistry.fromMarcadores([target])),
          marcadores: [target],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  Future<void> lock(FakeArTracker tracker, Marcador marcador) async {
    tracker.emit(
      ArDetection(
        trackerName: marcador.id,
        pose: Matrix4.identity(),
        isFullyTracked: true,
      ),
    );
    tracker.emit(
      ArDetection(
        trackerName: marcador.id,
        pose: Matrix4.identity(),
        isFullyTracked: true,
      ),
    );
  }

  testWidgets('el contenido del marcador solo aparece en ArLocked',
      (tester) async {
    final tracker = FakeArTracker();
    await pumpScan(tester, tracker: tracker);

    expect(find.byKey(const Key('ar-searching')), findsOneWidget);
    expect(find.byKey(const Key('ar-viewfinder')), findsOneWidget);
    expect(find.text('Apunta al logo del equipo…'), findsOneWidget);
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
    expect(find.byKey(const Key('ar-viewfinder')), findsOneWidget);
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
    expect(find.byKey(const Key('ar-viewfinder')), findsNothing);
    expect(find.byKey(const Key('ar-marker-content')), findsOneWidget);
    expect(find.text(titulo), findsOneWidget);
    expect(find.text(info), findsNothing);
    expect(find.text('SALIR'), findsNothing);
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

    expect(find.text('Apunta al logo de Leones de Yucatán'), findsOneWidget);
    expect(find.byKey(const Key('ar-viewfinder')), findsOneWidget);
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

      expect(find.byKey(const Key('ar-failed')), findsOneWidget,
          reason: failure.name);
      expect(find.text(expected[failure]!.$1), findsOneWidget);
      expect(find.text(expected[failure]!.$2), findsOneWidget);
      expect(find.text(ArFailedPanel.manualPathLabel.toUpperCase()),
          findsOneWidget);
      expect(find.byKey(const Key('ar-marker-content')), findsNothing);
    }

    await tester.tap(find.text(ArFailedPanel.manualPathLabel.toUpperCase()));
    await tester.pumpAndSettle();
    expect(find.text('lista-equipos'), findsOneWidget);
  });

  testWidgets('permiso denegado abre ajustes y no la lista de equipos', (
    tester,
  ) async {
    var settingsOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.teams: (_) => const Scaffold(body: Text('lista-equipos')),
        },
        home: ArFailedPanel(
          failure: const ArFailed(failure: ArTrackerFailure.permissionDenied),
          onRetry: () {},
          onOpenSettings: () => settingsOpened = true,
          onInstall: () {},
        ),
      ),
    );

    await tester.tap(find.text('ABRIR AJUSTES'));
    await tester.pump();

    expect(settingsOpened, isTrue);
    expect(find.text('lista-equipos'), findsNothing);
  });

  testWidgets('ARCore faltante abre instalar y no la lista de equipos', (
    tester,
  ) async {
    var installOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.teams: (_) => const Scaffold(body: Text('lista-equipos')),
        },
        home: ArFailedPanel(
          failure: const ArFailed(failure: ArTrackerFailure.arCoreNeedsInstall),
          onRetry: () {},
          onOpenSettings: () {},
          onInstall: () => installOpened = true,
        ),
      ),
    );

    await tester.tap(find.text('INSTALAR'));
    await tester.pump();

    expect(installOpened, isTrue);
    expect(find.text('lista-equipos'), findsNothing);
  });

  testWidgets('las acciones solo existen tras el lock y no cubren info', (
    tester,
  ) async {
    final tracker = FakeArTracker();
    await pumpScan(tester, tracker: tracker);

    expect(find.byKey(const Key('ar-actions')), findsNothing);
    expect(find.byKey(const Key('ar-action-gesto')), findsNothing);
    expect(find.byKey(const Key('ar-action-info')), findsNothing);
    expect(find.byKey(const Key('ar-action-efecto')), findsNothing);

    tracker.emit(
      ArDetection(
        trackerName: leones.id,
        pose: Matrix4.identity(),
        isFullyTracked: true,
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('ar-actions')), findsNothing);

    await lock(tracker, leones);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('ar-locked')), findsOneWidget);
    expect(find.byKey(const Key('ar-actions')), findsOneWidget);
    expect(find.byKey(const Key('ar-action-gesto')), findsNothing);
    expect(find.byKey(const Key('ar-action-info')), findsOneWidget);
    expect(find.byKey(const Key('ar-action-efecto')), findsOneWidget);
    expect(find.text(info), findsNothing);
    expect(find.text('SALIR'), findsNothing);

    await tester.tap(find.byKey(const Key('ar-action-info')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tracker.presentationYaw, greaterThan(0));
    expect(find.byKey(const Key('ar-info-panel')), findsOneWidget);
    expect(find.text(info), findsOneWidget);

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
    expect(find.byKey(const Key('ar-locked')), findsOneWidget);
    expect(find.byKey(const Key('ar-actions')), findsOneWidget);
    expect(find.byKey(const Key('ar-marker-content')), findsOneWidget);
    expect(find.text('Vuelve a apuntar a $titulo.'), findsOneWidget);
    expect(find.text(info), findsOneWidget);
  });

  testWidgets('permite cambiar el modelo sin salir de la sesión AR', (
    tester,
  ) async {
    final tracker = FakeArTracker();
    await pumpScan(tester, tracker: tracker);
    await lock(tracker, leones);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('ar-model-selector')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ar-model-player')));
    await tester.pump();
    await tester.pump();

    expect(
      tracker.attachedModels.last.glbAsset,
      'assets/models/leones_yucatan/jugador.glb',
    );
    expect(
      tracker.playedClips.last.clipName,
      kClipIdle,
    );
    expect(find.byKey(const Key('ar-action-gesto')), findsOneWidget);
    expect(find.byKey(const Key('ar-locked')), findsOneWidget);
    expect(find.byKey(const Key('ar-model-selector')), findsOneWidget);
  });

  testWidgets('deshabilita información mientras la trivia está activa', (
    tester,
  ) async {
    final tracker = FakeArTracker();
    await pumpScan(tester, tracker: tracker);
    await lock(tracker, leones);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('TRIVIA AR'));
    await tester.pump();

    final infoButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('ar-action-info')),
    );
    expect(infoButton.onPressed, isNull);
    expect(find.byKey(const Key('ar-trivia')), findsOneWidget);
  });

  testWidgets('celebracion pide el clip y reposo vuelve a idle',
      (tester) async {
    final player = _marcador(
      id: 'marcador_jugador_olmecas',
      titulo: 'El legado olmeca',
      infoTexto: 'Los Olmecas de Tabasco honran a la civilización olmeca.',
      tipo: TipoMarcador.jugador,
      animaciones: const [kClipIdle, kClipGesto, kClipCelebracion],
    );
    final tracker = FakeArTracker();
    await pumpScan(tester, tracker: tracker, marcador: player);

    expect(find.byKey(const Key('ar-actions')), findsNothing);

    await lock(tracker, player);
    await tester.pump();
    await tester.pump();

    expect(
      tracker.playedClips,
      contains(
        (trackerName: player.id, clipName: kClipIdle, loop: true),
      ),
    );
    expect(find.byKey(const Key('ar-action-gesto')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ar-action-gesto')));
    await tester.pump();
    await tester.pump();

    expect(find.text('REPOSO'), findsOneWidget);
    expect(
      tracker.playedClips.last,
      (trackerName: player.id, clipName: kClipCelebracion, loop: false),
    );
    expect(tracker.attachedEffects, isNotEmpty);
    expect(tracker.attachedEffects.last.glbAsset, kEfectoJonronAsset);
    expect(find.byKey(const Key('ar-vfx-banner')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ar-action-gesto')));
    await tester.pump();
    await tester.pump();

    expect(find.text('CELEBRACIÓN'), findsOneWidget);
    expect(
      tracker.playedClips.last,
      (trackerName: player.id, clipName: kClipIdle, loop: true),
    );
    expect(tracker.clearEffectCount, greaterThan(0));
  });

  testWidgets('efecto jonrón coloca el GLB 3D sin soltar la sesión',
      (tester) async {
    final tracker = FakeArTracker();
    await pumpScan(tester, tracker: tracker);

    await lock(tracker, leones);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('ar-action-efecto')), findsOneWidget);
    expect(tracker.attachedEffects, isEmpty);

    await tester.tap(find.byKey(const Key('ar-action-efecto')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('QUITAR EFECTO'), findsOneWidget);
    expect(tracker.attachedEffects, isNotEmpty);
    expect(tracker.attachedEffects.last.glbAsset, kEfectoJonronAsset);
    expect(tracker.effectProgress, greaterThan(0));
    expect(find.byKey(const Key('ar-vfx-banner')), findsOneWidget);
    expect(find.byKey(const Key('ar-locked')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ar-action-efecto')));
    await tester.pump();
    await tester.pump();

    expect(find.text('EFECTO JONRÓN'), findsOneWidget);
    expect(tracker.clearEffectCount, greaterThan(0));
    expect(find.byKey(const Key('ar-locked')), findsOneWidget);
  });
}
