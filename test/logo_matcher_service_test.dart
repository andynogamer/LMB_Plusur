import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lmb_plusur/services/logo_matcher_service.dart';
import 'package:lmb_plusur/theme/app_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog maps all 10 Zona Sur equipos to logo assets', () {
    expect(AppAssets.teamLogoById, hasLength(10));
    expect(AppAssets.logoForEquipo('guerreros_oaxaca'), isNotNull);
    expect(AppAssets.logoForEquipo('desconocido'), isNull);
  });

  test('LogoMatcherService recognizes a bundled logo as its equipo id', () async {
    final matcher = LogoMatcherService();
    final asset = AppAssets.teamLogoById['pericos_puebla']!;
    final id = await matcher.matchAsset(asset);
    expect(id, 'pericos_puebla');
    expect(matcher.catalogSize, greaterThanOrEqualTo(10));
  });

  test('LogoMatcherService distinguishes different team logos', () async {
    final matcher = LogoMatcherService();
    final a = await matcher.matchAsset(AppAssets.teamLogoById['diablos_rojos']!);
    final b = await matcher.matchAsset(AppAssets.teamLogoById['leones_yucatan']!);
    expect(a, 'diablos_rojos');
    expect(b, 'leones_yucatan');
    expect(a, isNot(b));
  });

  test('camera path matches each bundled logo to itself', () async {
    final matcher = LogoMatcherService();
    for (final entry in AppAssets.teamLogoById.entries) {
      final bytes = (await rootBundle.load(entry.value)).buffer.asUint8List();
      final match = await matcher.matchFromCamera(bytes);
      expect(match?.accepted, isTrue, reason: entry.key);
      expect(match?.equipoId, entry.key, reason: entry.key);
    }
  });

  test('camera path maps a padded photo-like logo to the same equipo', () async {
    final matcher = LogoMatcherService();
    for (final id in const [
      'diablos_rojos',
      'guerreros_oaxaca',
      'pericos_puebla',
      'aguila_veracruz',
      'bravos_leon',
    ]) {
      final bytes = await _paddedLogo(AppAssets.teamLogoById[id]!, scale: 0.52);
      final match = await matcher.matchFromCamera(bytes);
      expect(match?.accepted, isTrue, reason: id);
      expect(match?.equipoId, id, reason: id);
    }
  });

  test('a team-menu hint cannot steal a different logo', () async {
    final matcher = LogoMatcherService();
    final bytes =
        (await rootBundle.load(AppAssets.teamLogoById['pericos_puebla']!))
            .buffer
            .asUint8List();
    final match = await matcher.matchFromCamera(
      bytes,
      preferEquipoId: 'diablos_rojos',
    );
    expect(match?.accepted, isTrue);
    expect(match?.equipoId, 'pericos_puebla');
  });

  test('diablos is not mapped to aguila', () async {
    final matcher = LogoMatcherService();
    final bytes = await _paddedLogo(
      AppAssets.teamLogoById['diablos_rojos']!,
      scale: 0.5,
    );
    final match = await matcher.matchFromCamera(bytes);
    expect(match?.equipoId, isNot('aguila_veracruz'));
    expect(match?.equipoId, 'diablos_rojos');
    expect(match?.accepted, isTrue);
  });

  test('a flat red field is not accepted as El Aguila', () async {
    final matcher = LogoMatcherService();
    final red = img.Image(width: 96, height: 96);
    img.fill(red, color: img.ColorRgb8(176, 18, 24));
    final bytes = Uint8List.fromList(img.encodePng(red));
    final match = await matcher.matchFromCamera(bytes);
    expect(match?.accepted ?? false, isFalse);
  });

  test('busy noise is not accepted as a team', () async {
    final matcher = LogoMatcherService();
    final noise = img.Image(width: 128, height: 128);
    for (var y = 0; y < noise.height; y++) {
      for (var x = 0; x < noise.width; x++) {
        noise.setPixelRgb(
          x,
          y,
          (x * 13 + y * 7) % 255,
          (x * 5 + y * 17) % 255,
          (x * 29 + y) % 255,
        );
      }
    }
    final bytes = Uint8List.fromList(img.encodePng(noise));
    final match = await matcher.matchFromCamera(bytes);
    expect(match?.accepted ?? false, isFalse);
  });
}

Future<Uint8List> _paddedLogo(String assetPath, {required double scale}) async {
  final raw = (await rootBundle.load(assetPath)).buffer.asUint8List();
  final src = img.decodeImage(raw);
  expect(src, isNotNull);
  final side = src!.width > src.height ? src.width : src.height;
  final canvas = (side / scale).round();
  final out = img.Image(width: canvas, height: canvas);
  img.fill(out, color: img.ColorRgb8(228, 224, 214));
  img.compositeImage(out, src, center: true);
  return Uint8List.fromList(img.encodePng(out));
}
