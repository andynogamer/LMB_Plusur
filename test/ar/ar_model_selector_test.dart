import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/models/marcador_model.dart';
import 'package:lmb_plusur/screens/ar/widgets/ar_model_selector.dart';

void main() {
  const marcador = Marcador(
    id: 'marcador_estadio_leones',
    equipoId: 'leones_yucatan',
    tipo: TipoMarcador.estadio,
    titulo: 'Parque Kukulcán',
    infoTexto: 'Casa de los Leones.',
    markerImage: 'assets/markers/marcador_estadio_leones.png',
    modelAsset: 'assets/models/marcador_estadio_leones/modelo.glb',
    anchoMetros: 0.15,
  );

  testWidgets('ofrece estadio y jugador tras detectar el equipo', (
    tester,
  ) async {
    var choice = ArModelChoice.defaultModel;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => ArModelSelector(
            marcador: marcador,
            choice: choice,
            onChanged: (next) => setState(() => choice = next),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('ar-model-selector')), findsOneWidget);
    await tester.tap(find.text('JUGADOR'));
    await tester.pump();
    expect(choice, ArModelChoice.player);
    await tester.tap(find.text('ESTADIO'));
    await tester.pump();
    expect(choice, ArModelChoice.stadium);
  });
}
