import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/models/marcador_model.dart';
import 'package:lmb_plusur/theme/app_colors.dart';
import 'package:lmb_plusur/widgets/ar_model_viewport.dart';

void main() {
  testWidgets('ArModelViewport muestra etiqueta de modelo 3D', (tester) async {
    const marcador = Marcador(
      id: 'marcador_estadio_diablos',
      equipoId: 'diablos_rojos',
      tipo: TipoMarcador.estadio,
      titulo: 'Estadio demo',
      infoTexto: 'Info',
      markerImage: 'assets/images/team-logos/diablos_rojos_mexico/logo_base.png',
      modelAsset: 'assets/models/placeholders/estadio.glb',
      animaciones: ['idle'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.navy,
          body: SizedBox(
            height: 320,
            child: ArModelViewport(marcador: marcador),
          ),
        ),
      ),
    );

    expect(find.textContaining('MODELO 3D'), findsOneWidget);
    expect(find.textContaining('ESTADIO'), findsOneWidget);
  });
}
