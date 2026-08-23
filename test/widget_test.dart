import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/app.dart';

void main() {
  testWidgets('La app inicia en la pantalla de carga', (tester) async {
    await tester.pumpWidget(const LmbPlusurApp());
    expect(find.text('CARGANDO'), findsOneWidget);
  });
}
