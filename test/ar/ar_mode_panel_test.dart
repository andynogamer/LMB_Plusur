import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/models/equipo_model.dart';
import 'package:lmb_plusur/models/trivia_model.dart';
import 'package:lmb_plusur/models/marcador_model.dart';
import 'package:lmb_plusur/screens/ar/widgets/ar_mode_panel.dart';

class _FixedRandom implements math.Random {
  @override
  double nextDouble() => 0.5;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

void main() {
  const equipo = Equipo(
    id: 'leones_yucatan',
    nombre: 'Leones de Yucatán',
    historia: 'Historia',
    fundacion: 1954,
    trivias: [
      Trivia(
        id: 1,
        pregunta: 'Pregunta uno de los Leones',
        opciones: ['Mérida', 'Puebla'],
        respuestaCorrecta: 0,
      ),
      Trivia(
        id: 2,
        pregunta: 'Pregunta dos de los Leones',
        opciones: ['Campeche', 'Mérida'],
        respuestaCorrecta: 0,
      ),
      Trivia(
        id: 3,
        pregunta: 'Pregunta tres de los Leones',
        opciones: ['Yucatán', 'Oaxaca'],
        respuestaCorrecta: 0,
      ),
      Trivia(
        id: 4,
        pregunta: 'Pregunta cuatro de los Leones',
        opciones: ['Leones', 'Piratas'],
        respuestaCorrecta: 0,
      ),
      Trivia(
        id: 5,
        pregunta: 'Pregunta cinco de los Leones',
        opciones: ['1954', '2000'],
        respuestaCorrecta: 0,
      ),
    ],
  );
  const marcador = Marcador(
    id: 'marcador_estadio_leones',
    equipoId: 'leones_yucatan',
    tipo: TipoMarcador.estadio,
    titulo: 'Parque Kukulcán',
    infoTexto: 'Casa de los Leones.',
    markerImage: 'assets/markers/marcador_estadio_leones.png',
    modelAsset: 'assets/models/marcador_estadio_leones/modelo.glb',
    anchoMetros: 0.15,
    animaciones: [],
  );

  testWidgets('permite cambiar entre galería y trivia en una sesión', (
    tester,
  ) async {
    var mode = ArExperienceMode.gallery;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => ArModePanel(
            marcador: marcador,
            equipo: equipo,
            mode: mode,
            triviaRandom: _FixedRandom(),
            onModeChanged: (next) => setState(() => mode = next),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('ar-trivia')), findsNothing);
    await tester.tap(find.text('TRIVIA AR'));
    await tester.pump();

    expect(mode, ArExperienceMode.trivia);
    expect(find.byKey(const Key('ar-trivia')), findsOneWidget);
    expect(find.byKey(const Key('ar-trivia-question')), findsOneWidget);
    expect(find.textContaining('Pregunta 1 de 5'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ar-trivia-answer-0')));
    await tester.pump();
    expect(find.text('¡Correcto!'), findsOneWidget);
  });

  testWidgets(
    'completa cinco preguntas, cuenta una respuesta y permite replay',
    (tester) async {
      var mode = ArExperienceMode.gallery;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => ArModePanel(
              marcador: marcador,
              equipo: equipo,
              mode: mode,
              triviaRandom: _FixedRandom(),
              onModeChanged: (next) => setState(() => mode = next),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('ar-mode-trivia')));
      await tester.pump();

      final shownQuestions = <String>{};
      for (var question = 0; question < 5; question++) {
        final prompt = tester.widget<Text>(
          find.byKey(const Key('ar-trivia-question')),
        );
        shownQuestions.add(prompt.data!);
        expect(
          find.textContaining('Pregunta ${question + 1} de 5'),
          findsOneWidget,
        );
        if (question == 2) {
          await tester.tap(find.byKey(const Key('ar-trivia-answer-1')));
          await tester.pump();
          expect(
            find.textContaining('Incorrecto. Respuesta correcta:'),
            findsOneWidget,
          );
          expect(find.text('Pregunta 3 de 5  ·  Aciertos: 2'), findsOneWidget);
          expect(
            tester
                .widget<OutlinedButton>(
                  find.byKey(const Key('ar-trivia-answer-0')),
                )
                .onPressed,
            isNull,
          );
          await tester.tap(find.byKey(const Key('ar-trivia-answer-0')));
          await tester.pump();
          expect(find.text('Pregunta 3 de 5  ·  Aciertos: 2'), findsOneWidget);
        } else {
          await tester.tap(find.byKey(const Key('ar-trivia-answer-0')));
          await tester.pump();
          expect(find.text('¡Correcto!'), findsOneWidget);
        }
        await tester.tap(find.byKey(const Key('ar-trivia-next')));
        await tester.pump();
      }

      expect(shownQuestions, hasLength(5));
      expect(find.byKey(const Key('ar-trivia-finished')), findsOneWidget);
      expect(find.text('Puntaje final: 4/5'), findsOneWidget);
      await tester.tap(find.byKey(const Key('ar-trivia-replay')));
      await tester.pump();
      expect(find.byKey(const Key('ar-trivia')), findsOneWidget);
      expect(find.text('Pregunta 1 de 5  ·  Aciertos: 0'), findsOneWidget);
      expect(find.byKey(const Key('ar-trivia-finish')), findsNothing);
    },
  );

  testWidgets('no ofrece Trivia AR si faltan cinco preguntas vinculadas', (
    tester,
  ) async {
    const equipoIncompleto = Equipo(
      id: 'leones_yucatan',
      nombre: 'Leones de Yucatán',
      historia: 'Historia',
      fundacion: 1954,
      trivias: [
        Trivia(
          id: 1,
          pregunta: 'Pregunta única',
          opciones: ['A', 'B'],
          respuestaCorrecta: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArModePanel(
            marcador: marcador,
            equipo: equipoIncompleto,
            mode: ArExperienceMode.gallery,
            onModeChanged: _ignoreModeChange,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('ar-mode-trivia')), findsNothing);
    expect(find.byKey(const Key('ar-trivia-unavailable')), findsOneWidget);
    expect(find.textContaining('cinco preguntas distintas'), findsOneWidget);
  });

  testWidgets('no vincula trivia de un equipo a otro marcador', (tester) async {
    const equipoAjeno = Equipo(
      id: 'olmecas_tabasco',
      nombre: 'Olmecas de Tabasco',
      historia: 'Historia',
      fundacion: 1978,
      trivias: [],
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArModePanel(
            marcador: marcador,
            equipo: equipoAjeno,
            mode: ArExperienceMode.gallery,
            onModeChanged: _ignoreModeChange,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('ar-mode-trivia')), findsNothing);
    expect(find.byKey(const Key('ar-trivia-unavailable')), findsOneWidget);
  });

  testWidgets('los tres modos caben en un ancho de teléfono compacto', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 252,
            child: ArModePanel(
              marcador: marcador,
              equipo: equipo,
              mode: ArExperienceMode.gallery,
              onModeChanged: _ignoreModeChange,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('ar-mode-home-run')), findsOneWidget);
  });

  testWidgets('el mejor puntaje se conserva al cambiar de modo', (
    tester,
  ) async {
    var mode = ArExperienceMode.gallery;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: SizedBox(
              width: 360,
              child: ArModePanel(
                marcador: marcador,
                equipo: equipo,
                mode: mode,
                homeRunRandom: _FixedRandom(),
                onModeChanged: (next) => setState(() => mode = next),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('ar-mode-home-run')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ar-home-run-swing')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.tap(find.byKey(const Key('ar-home-run-swing')));
    await tester.pump();

    expect(_scoreValue(tester, 'ar-home-run-best-score'), '1');

    await tester.tap(find.byKey(const Key('ar-mode-trivia')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ar-mode-home-run')));
    await tester.pump();

    expect(_scoreValue(tester, 'ar-home-run-best-score'), '1');
  });
}

void _ignoreModeChange(ArExperienceMode mode) {}

String _scoreValue(WidgetTester tester, String key) {
  final value = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(Text),
  );
  return tester.widgetList<Text>(value).last.data!;
}
