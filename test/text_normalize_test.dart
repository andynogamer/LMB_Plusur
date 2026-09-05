import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/utils/text_normalize.dart';

void main() {
  group('normalizeSearchText', () {
    test('lowercases and strips Spanish accents', () {
      expect(normalizeSearchText('Yucatán'), 'yucatan');
      expect(normalizeSearchText('Águila'), 'aguila');
      expect(normalizeSearchText('  León  '), 'leon');
    });

    test('matches accent-insensitive contains use case', () {
      final nombre = normalizeSearchText('Leones de Yucatán');
      expect(nombre.contains(normalizeSearchText('yucatan')), isTrue);
      expect(nombre.contains(normalizeSearchText('YUCATÁN')), isTrue);
    });
  });
}
