
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../models/marcador_model.dart';
import '../theme/app_assets.dart';

/// Result of comparing a camera photo against bundled team logos.
class CameraLogoMatch {
  const CameraLogoMatch({
    required this.equipoId,
    required this.distance,
    required this.accepted,
  });

  /// Lower is closer (mean absolute difference, 0?255).
  final String equipoId;
  final int distance;
  final bool accepted;
}

/// Image recognition helper (SP-01 / US-06).
///
/// Asset self-checks use average-hash. Camera photos use a center-crop
/// grayscale fingerprint, because a full-frame hash never matches a logo
/// sitting in the middle of the preview.
class LogoMatcherService {
  LogoMatcherService();

  final Map<String, BigInt> _hashesByEquipoId = {};
  final Map<String, BigInt> _hashesByMarcadorId = {};
  final Map<String, List<int>> _printsByEquipoId = {};
  bool _equiposLoaded = false;

  Future<void> ensureEquipoLogosLoaded() async {
    if (_equiposLoaded) return;
    for (final entry in AppAssets.teamLogoById.entries) {
      final bytes = (await rootBundle.load(entry.value)).buffer.asUint8List();
      final hash = averageHash(bytes);
      if (hash != null) _hashesByEquipoId[entry.key] = hash;
      final print = _printFromBytes(bytes);
      if (print != null) _printsByEquipoId[entry.key] = print;
    }
    _equiposLoaded = true;
  }

  Future<void> loadMarcadores(List<Marcador> marcadores) async {
    _hashesByMarcadorId.clear();
    for (final marcador in marcadores) {
      final bytes =
          (await rootBundle.load(marcador.markerImage)).buffer.asUint8List();
      final hash = averageHash(bytes);
      if (hash != null) _hashesByMarcadorId[marcador.id] = hash;
    }
  }

  Future<String?> matchBytes(
    Uint8List bytes, {
    int maxHammingDistance = 12,
  }) async {
    await ensureEquipoLogosLoaded();
    return _bestHashMatch(
      bytes,
      _hashesByEquipoId,
      maxHammingDistance: maxHammingDistance,
    );
  }

  Future<String?> matchMarcadorBytes(
    Uint8List bytes, {
    int maxHammingDistance = 14,
  }) async {
    if (_hashesByMarcadorId.isEmpty) return null;
    return _bestHashMatch(
      bytes,
      _hashesByMarcadorId,
      maxHammingDistance: maxHammingDistance,
    );
  }

  Future<String?> matchAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return matchBytes(data.buffer.asUint8List());
  }

  Future<String?> matchMarcadorAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return matchMarcadorBytes(data.buffer.asUint8List());
  }

  /// Compare a camera JPEG/PNG to team logos. Always returns the closest
  /// team when a fingerprint can be built, with [CameraLogoMatch.accepted]
  /// when the score is strong enough to open AR.
  Future<CameraLogoMatch?> matchFromCamera(
    Uint8List bytes, {
    String? preferEquipoId,
  }) async {
    await ensureEquipoLogosLoaded();
    final decoded = img.decodeImage(bytes);
    if (decoded == null || _printsByEquipoId.isEmpty) return null;
    final oriented = img.bakeOrientation(decoded);

    CameraLogoMatch? closest;
    for (final crop in const [0.78, 0.55, 0.38, 1.0]) {
      final probe = _grayGrid(oriented, crop: crop);
      if (probe == null) continue;
      final ranked = _rankByMad(probe);
      if (ranked.isEmpty) continue;

      var top = ranked.first;
      if (preferEquipoId != null) {
        final hinted = ranked.where((e) => e.id == preferEquipoId);
        if (hinted.isNotEmpty && hinted.first.distance <= top.distance + 8) {
          top = hinted.first;
        }
      }

      final second = ranked.length > 1 ? ranked[1].distance : 255;
      final margin = second - top.distance;
      final accepted = top.distance <= 34 ||
          (top.distance <= 52 && margin >= 5) ||
          (preferEquipoId == top.id && top.distance <= 60);

      final candidate = CameraLogoMatch(
        equipoId: top.id,
        distance: top.distance,
        accepted: accepted,
      );
      if (closest == null || candidate.distance < closest.distance) {
        closest = candidate;
      }
      if (accepted && candidate.distance <= 42) return candidate;
    }

    if (closest != null) {
      debugPrint(
        'LMB_SCAN closest=${closest.equipoId} dist=${closest.distance} '
        'accepted=${closest.accepted}',
      );
    }
    return closest;
  }

  String? _bestHashMatch(
    Uint8List bytes,
    Map<String, BigInt> catalog, {
    required int maxHammingDistance,
  }) {
    final probe = averageHash(bytes);
    if (probe == null || catalog.isEmpty) return null;

    String? bestId;
    var bestDistance = 65;
    catalog.forEach((id, hash) {
      final distance = hammingDistance(probe, hash);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestId = id;
      }
    });

    if (bestId == null || bestDistance > maxHammingDistance) return null;
    return bestId;
  }

  List<({String id, int distance})> _rankByMad(List<int> probe) {
    final ranked = <({String id, int distance})>[];
    _printsByEquipoId.forEach((id, print) {
      ranked.add((id: id, distance: _mad(probe, print)));
    });
    ranked.sort((a, b) => a.distance.compareTo(b.distance));
    return ranked;
  }

  List<int>? _printFromBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    return _grayGrid(img.bakeOrientation(decoded), crop: 1);
  }

  static List<int>? _grayGrid(img.Image source, {required double crop}) {
    var image = source;
    if (crop < 0.99) {
      final width = (image.width * crop).round().clamp(8, image.width);
      final height = (image.height * crop).round().clamp(8, image.height);
      final x = ((image.width - width) / 2).round();
      final y = ((image.height - height) / 2).round();
      image = img.copyCrop(image, x: x, y: y, width: width, height: height);
    }
    final small = img.copyResize(
      image,
      width: 16,
      height: 16,
      interpolation: img.Interpolation.average,
    );
    final out = <int>[];
    for (var y = 0; y < 16; y++) {
      for (var x = 0; x < 16; x++) {
        final p = small.getPixel(x, y);
        out.add(((p.r + p.g + p.b) / 3).round());
      }
    }
    return out;
  }

  static int _mad(List<int> a, List<int> b) {
    final n = a.length < b.length ? a.length : b.length;
    if (n == 0) return 255;
    var sum = 0;
    for (var i = 0; i < n; i++) {
      sum += (a[i] - b[i]).abs();
    }
    return sum ~/ n;
  }

  static BigInt? averageHash(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final small = img.copyResize(decoded, width: 8, height: 8);
    var sum = 0;
    final grays = <int>[];
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        final p = small.getPixel(x, y);
        final g = ((p.r + p.g + p.b) / 3).round();
        grays.add(g);
        sum += g;
      }
    }
    final avg = sum / grays.length;
    var hash = BigInt.zero;
    for (var i = 0; i < grays.length; i++) {
      if (grays[i] >= avg) hash |= (BigInt.one << i);
    }
    return hash;
  }

  static int hammingDistance(BigInt a, BigInt b) {
    var x = a ^ b;
    var count = 0;
    while (x > BigInt.zero) {
      if ((x & BigInt.one) == BigInt.one) count++;
      x >>= 1;
    }
    return count;
  }

  int get catalogSize => _hashesByEquipoId.length;
  int get marcadorCatalogSize => _hashesByMarcadorId.length;
}
