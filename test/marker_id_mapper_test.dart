import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/services/marker_id_mapper.dart';
import 'package:lmb_plusur/theme/app_assets.dart';

void main() {
  test('AR plugin stem maps to the matching equipo id', () {
    expect(MarkerIdMapper.equipoIdFromImageName('diablos_rojos'), 'diablos_rojos');
    expect(
      MarkerIdMapper.equipoIdFromImageName('pericos_puebla.png'),
      'pericos_puebla',
    );
    expect(
      MarkerIdMapper.equipoIdFromImageName(
        'assets/markers/guerreros_oaxaca.png',
      ),
      'guerreros_oaxaca',
    );
  });

  test('each tracking marker filename is unique and keyed by equipo id', () {
    final stems = <String>{};
    for (final entry in AppAssets.trackingMarkerById.entries) {
      final file = entry.value.split('/').last;
      final stem = file.substring(0, file.lastIndexOf('.'));
      expect(stem, entry.key);
      expect(stems.add(stem), isTrue, reason: 'duplicate stem $stem');
    }
    expect(stems, hasLength(10));
  });

  test('ambiguous logo_base filename does not pick a team', () {
    expect(MarkerIdMapper.equipoIdFromImageName('logo_base'), isNull);
    expect(MarkerIdMapper.equipoIdFromImageName('logo_base.png'), isNull);
  });
}
