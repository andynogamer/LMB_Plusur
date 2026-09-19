import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/screens/ar/widgets/ar_model_selector.dart';

void main() {
  testWidgets('ofrece estadio y jugador tras detectar el equipo', (
    tester,
  ) async {
    var choice = ArModelChoice.defaultModel;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => ArModelSelector(
            choice: choice,
            onChanged: (next) => setState(() => choice = next),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('ar-model-selector')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ar-model-player')));
    await tester.pump();
    expect(choice, ArModelChoice.player);
    await tester.tap(find.byKey(const Key('ar-model-stadium')));
    await tester.pump();
    expect(choice, ArModelChoice.stadium);
  });
}
