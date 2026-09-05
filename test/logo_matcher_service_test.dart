import 'package:flutter_test/flutter_test.dart';
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
}
