import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/ar/ar_tracker.dart';
import 'package:lmb_plusur/ar/trackers/arcore_image_tracker.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('a paused or last-known image is never fully tracked', () {
    expect(
      imageIsFullyTracked(
        trackingMethod: 'FULL_TRACKING',
        trackingState: 'TRACKING',
      ),
      isTrue,
    );
    expect(
      imageIsFullyTracked(
        trackingMethod: 'FULL_TRACKING',
        trackingState: 'PAUSED',
      ),
      isFalse,
    );
    expect(
      imageIsFullyTracked(
        trackingMethod: 'FULL_TRACKING',
        trackingState: 'STOPPED',
      ),
      isFalse,
    );
    expect(
      imageIsFullyTracked(
        trackingMethod: 'LAST_KNOWN_POSE',
        trackingState: 'TRACKING',
      ),
      isFalse,
    );
    expect(imageIsFullyTracked(), isFalse);
  });

  test('reference name is the filename stem, never rewritten', () {
    expect(
      referenceImageStem('assets/markers/marcador_estadio_leones.png'),
      'marcador_estadio_leones',
    );
    expect(
      referenceImageStem('assets/markers/marcador_jugador_olmecas.png'),
      'marcador_jugador_olmecas',
    );
  });

  test('a mismatched name or missing width cannot enter the database', () {
    expect(
      () => assertTrackableReferences(const [
        ArReferenceImage(
          name: 'guessed_club',
          assetPath: 'assets/markers/marcador_estadio_leones.png',
          physicalWidthMeters: 0.15,
        ),
      ]),
      throwsA(
        isA<ArTrackerException>().having(
          (error) => error.failure,
          'failure',
          ArTrackerFailure.databaseBuildFailed,
        ),
      ),
    );

    expect(
      () => assertTrackableReferences(const [
        ArReferenceImage(
          name: 'marcador_estadio_leones',
          assetPath: 'assets/markers/marcador_estadio_leones.png',
          physicalWidthMeters: 0,
        ),
      ]),
      throwsA(isA<ArTrackerException>()),
    );

    expect(
      () => assertTrackableReferences(const []),
      throwsA(isA<ArTrackerException>()),
    );

    expect(
      () => assertTrackableReferences(const [
        ArReferenceImage(
          name: 'marcador_estadio_leones',
          assetPath: 'assets/markers/marcador_estadio_leones.png',
          physicalWidthMeters: 0.15,
        ),
      ]),
      returnsNormally,
    );
  });

  test(
      'a missing or failed model has Spanish copy and does not pretend it placed',
      () {
    expect(modelFallbackCopy(null), isNull);
    expect(
      modelFallbackCopy(
        const ArModelAttach(
            ArModelAttachKind.placed, 'marcador_estadio_leones'),
      ),
      isNull,
    );
    expect(
      modelFallbackCopy(
        const ArModelAttach(
            ArModelAttachKind.missing, 'marcador_estadio_leones'),
      ),
      contains('Aún no hay modelo 3D'),
    );
    expect(
      modelFallbackCopy(
        const ArModelAttach(
            ArModelAttachKind.failed, 'marcador_estadio_leones'),
      ),
      contains('El escaneo sigue activo'),
    );
  });

  test('continuous tracking is on so the debounce gate can confirm', () {
    expect(kContinuousImageTracking, isTrue);
    expect(kImageTrackingUpdateIntervalMs, inInclusiveRange(50, 400));
  });

  test('lays the model parallel to the marker image plane', () {
    final pose = modelPoseForImage(Matrix4.identity());
    final origin = pose.transform3(Vector3.zero());
    final modelUp = pose.transform3(Vector3(0, 1, 0));
    final modelNormal = pose.transform3(Vector3(0, 0, 1));

    final upDirection = modelUp - origin;
    final normalDirection = modelNormal - origin;

    expect(upDirection.x, closeTo(0, 0.000001));
    expect(upDirection.y, closeTo(0, 0.000001));
    expect(upDirection.z, closeTo(-1, 0.000001));
    expect(normalDirection.x, closeTo(0, 0.000001));
    expect(normalDirection.y, closeTo(1, 0.000001));
    expect(normalDirection.z, closeTo(0, 0.000001));
  });
}
