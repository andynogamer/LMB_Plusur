import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/services/stats_simulator.dart';

void main() {
  test('avanza las estadísticas sin interacción del usuario', () async {
    final simulator = StatsSimulator(
      teamId: 'leones_yucatan',
      interval: const Duration(milliseconds: 10),
    );
    final initial = simulator.snapshot;
    var updates = 0;
    simulator.addListener(() => updates++);

    await Future<void>.delayed(const Duration(milliseconds: 35));

    expect(updates, greaterThanOrEqualTo(2));
    expect(simulator.snapshot.inning, isNot(initial.inning));
    expect(simulator.snapshot.localHits, greaterThan(initial.localHits));
    simulator.dispose();
  });

  test('el estado inicial es determinista por equipo', () {
    final first = StatsSimulator(teamId: 'piratas_campeche');
    final second = StatsSimulator(teamId: 'piratas_campeche');

    expect(second.snapshot.localScore, first.snapshot.localScore);
    expect(second.snapshot.visitantHits, first.snapshot.visitantHits);
    first.dispose();
    second.dispose();
  });
}
