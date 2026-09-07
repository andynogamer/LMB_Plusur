import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/services/image_detection_gate.dart';
import 'package:lmb_plusur/theme/app_assets.dart';

void main() {
  test('does not lock on the first ARCore hit', () {
    final gate = ImageDetectionGate(now: () => DateTime(2026, 9, 7, 12));
    expect(gate.observe('diablos_rojos'), isNull);
    expect(gate.observe('diablos_rojos'), 'diablos_rojos');
  });

  test('a flicker of another team restarts the count', () {
    final gate = ImageDetectionGate(now: () => DateTime(2026, 9, 7, 12));
    expect(gate.observe('guerreros_oaxaca'), isNull);
    expect(gate.observe('diablos_rojos'), isNull);
    expect(gate.observe('diablos_rojos'), 'diablos_rojos');
  });

  test('hinted session ignores a different team id', () {
    final gate = ImageDetectionGate(now: () => DateTime(2026, 9, 7, 12));
    expect(
      gate.observe(
        'guerreros_oaxaca',
        requiredEquipoId: 'diablos_rojos',
      ),
      isNull,
    );
    expect(
      gate.observe('diablos_rojos', requiredEquipoId: 'diablos_rojos'),
      isNull,
    );
    expect(
      gate.observe('diablos_rojos', requiredEquipoId: 'diablos_rojos'),
      'diablos_rojos',
    );
  });

  test('trackingImagePathsFor returns only the hinted marker', () {
    final paths = AppAssets.trackingImagePathsFor('pericos_puebla');
    expect(paths, ['assets/markers/pericos_puebla.png']);
    expect(AppAssets.trackingImagePaths, hasLength(10));
  });
}
