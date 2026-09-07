import 'package:vector_math/vector_math_64.dart';

/// A reference image registered in the tracking database.
///
/// [name] is the filename stem and MUST equal the Marcador.id.
/// [physicalWidthMeters] is the printed width — supplying it measurably
/// improves ARCore detection and pose accuracy, so it is required, not
/// optional.
class ArReferenceImage {
  const ArReferenceImage({
    required this.name,
    required this.assetPath,
    required this.physicalWidthMeters,
  });

  final String name;
  final String assetPath;
  final double physicalWidthMeters;
}

/// A detection reported by the platform tracker.
///
/// [trackerName] is the reference-image name registered in the tracking
/// database. It is deterministic and exact — never a similarity guess.
class ArDetection {
  const ArDetection({
    required this.trackerName,
    required this.pose,
    required this.isFullyTracked,
  });

  final String trackerName;
  final Matrix4 pose;

  /// False while ARCore has recognised the image but not yet localised it.
  /// Do not place 3D content until this is true (ARCore guidance).
  final bool isFullyTracked;
}

enum ArTrackerFailure {
  permissionDenied,
  arCoreUnavailable,
  arCoreNeedsInstall,
  databaseBuildFailed,
  sessionLost,
  unknown,
}

class ArTrackerException implements Exception {
  const ArTrackerException(this.failure, [this.cause]);

  final ArTrackerFailure failure;
  final Object? cause;

  @override
  String toString() => 'ArTrackerException($failure, $cause)';
}

abstract interface class ArTracker {
  /// Whether this device can run the tracker at all. Cheap; no session start.
  Future<bool> isSupported();

  /// Loads the reference-image database and starts the camera session.
  /// Throws [ArTrackerException] — never returns a half-started session.
  Future<void> start({required List<ArReferenceImage> references});

  /// Deterministic detections. Emits per tracked frame; may repeat.
  Stream<ArDetection> get detections;

  /// Attaches a GLB to a detected marker's pose. No-op for fakes.
  Future<void> attachModel({
    required String trackerName,
    required String glbAsset,
  });

  Future<void> stop();
  Future<void> dispose();
}
