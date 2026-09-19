import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/models/equipo_model.dart';
import 'package:lmb_plusur/models/trivia_model.dart';
import 'package:lmb_plusur/models/marcador_model.dart';
import 'package:lmb_plusur/screens/ar/widgets/ar_mode_panel.dart';

void main() {
  const equipo = Equipo(
    id: 'leones_yucatan',
    nombre: 'Leones de Yucatán',
    historia: 'Historia',
    fundacion: 1954,
    trivias: [
      Trivia(
        id: 1,
        pregunta: '¿Dónde juegan los Leones?',
        opciones: ['Mérida', 'Puebla'],
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
    expect(find.text('¿Dónde juegan los Leones?'), findsOneWidget);
    await tester.tap(find.text('Mérida'));
    await tester.pump();
    expect(find.text('¡Correcto!'), findsOneWidget);
  });
}
