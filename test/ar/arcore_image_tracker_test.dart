import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/ar/trackers/arcore_image_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('node removal accepts the plugin native null success result', () async {
    const channel = MethodChannel('test/ar_node_removal');
    String? removedName;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'removeNode');
      removedName = (call.arguments as Map<Object?, Object?>)['name'] as String;
      return null;
    });

    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await removeArSceneNode(channel, 'modelo_marcador_estadio_leones');

    expect(removedName, 'modelo_marcador_estadio_leones');
  });
}
