import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/services/feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FeedbackService respeta enabled=false sin lanzar', () async {
    final service = FeedbackService.instance;
    service.enabled = false;
    await service.tap();
    await service.success();
    await service.error();
    service.enabled = true;
  });

  test('debounce de tap no lanza en ráfaga', () async {
    final service = FeedbackService.instance;
    service.enabled = false;
    await Future.wait([
      service.tap(),
      service.tap(),
      service.tap(),
    ]);
    service.enabled = true;
  });
}
