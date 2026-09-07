import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/services/arcore_install.dart';

void main() {
  test('ARCore install helper is a no-op off Android', () async {
    final status = await ArCoreInstall.ensure();
    expect(status, ArCoreInstallStatus.unsupported);
  });
}
