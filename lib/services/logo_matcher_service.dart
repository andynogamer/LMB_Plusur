import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../theme/app_assets.dart';

/// Offline logo recognition helper for the AR spike (SP-01).
///
/// Uses average-hash distance against bundled team logos. This proves
/// image?equipoId matching for tests and as a camera-frame fallback.
/// Production AR pose/anchoring remains with [ar_flutter_plugin_plus]
/// (see docs/ar-spike.md).
class LogoMatcherService {
  LogoMatcherService();

  final Map<String, BigInt> _hashesByEquipoId = {};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    for (final entry in AppAssets.teamLogoById.entries) {
      final bytes = await rootBundle.load(entry.value);
      final hash = averageHash(bytes.buffer.asUint8List());
      if (hash != null) {
        _hashesByEquipoId[entry.key] = hash;
      }
    }
    _loaded = true;
  }

  /// Returns best matching equipo id, or null if no logo is close enough.
  Future<String?> matchBytes(
    Uint8List bytes, {
    int maxHammingDistance = 12,
  }) async {
    await ensureLoaded();
    final probe = averageHash(bytes);
    if (probe == null || _hashesByEquipoId.isEmpty) return null;

    String? bestId;
    var bestDistance = 65;
    _hashesByEquipoId.forEach((id, hash) {
      final distance = hammingDistance(probe, hash);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestId = id;
      }
    });

    if (bestId == null || bestDistance > maxHammingDistance) return null;
    return bestId;
  }

  Future<String?> matchAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return matchBytes(data.buffer.asUint8List());
  }

  /// 8x8 average hash (64-bit) ? fast and dependency-light.
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
      if (grays[i] >= avg) {
        hash |= (BigInt.one << i);
      }
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

  /// Convenience for debug UIs.
  int get catalogSize => _hashesByEquipoId.length;
}
