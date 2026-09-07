/// Boundary for Flutter-native AR (Constitution Article VI / SP-01).
///
/// Chosen stack: **ar_flutter_plugin_plus** for marker pose + 3D nodes.
/// MarkerIdMapper turns the plugin image name into Equipo.id.
/// Labeled demo mode remains for devices without ARCore/ARKit.
abstract class ArSessionFacade {
  Future<void> start({List<String> trackingImageAssetPaths});
  Future<void> stop();
  Stream<ArDetectionEvent> get detections;
}

class ArDetectionEvent {
  const ArDetectionEvent({
    required this.equipoId,
    required this.source,
    this.demo = false,
  });

  final String equipoId;
  final ArDetectionSource source;
  final bool demo;
}

enum ArDetectionSource { imageMarker, logoMatcher, demo }
