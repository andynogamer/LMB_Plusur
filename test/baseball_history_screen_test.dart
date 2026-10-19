import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/routes/app_routes.dart';
import 'package:lmb_plusur/screens/baseball_history_screen.dart';
import 'package:lmb_plusur/screens/main_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows detailed international baseball milestones', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BaseballHistoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('HISTORIA DEL BÉISBOL'), findsOneWidget);
    expect(find.text('El béisbol se vuelve profesional'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Las Ligas Negras organizan su propio campeonato'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Las Ligas Negras organizan su propio campeonato'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Jackie Robinson rompe la barrera racial de MLB'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Jackie Robinson rompe la barrera racial de MLB'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('El Clásico Mundial reúne selecciones'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('El Clásico Mundial reúne selecciones'), findsOneWidget);
    expect(find.text('Fuente histórica'), findsAtLeastNWidgets(1));
    expect(find.text('Imagen y licencia'), findsAtLeastNWidgets(1));
  });

  testWidgets('main screen opens the general baseball history section', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const MainScreen(),
        routes: {
          AppRoutes.baseballHistory: (_) => const BaseballHistoryScreen(),
        },
      ),
    );

    final historyEntry = find.text('HISTORIA DEL BÉISBOL');
    await tester.ensureVisible(historyEntry);
    await tester.tap(historyEntry);
    await tester.pumpAndSettle();

    expect(find.text('HISTORIA DEL BÉISBOL'), findsOneWidget);
    expect(find.text('El béisbol se vuelve profesional'), findsOneWidget);
  });
}
