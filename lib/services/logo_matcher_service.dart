import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../models/marcador_model.dart';
import '../theme/app_assets.dart';

/// Image recognition helper (SP-01 / US-06).
///
/// Average-hash matching against team logos and/or [Marcador.markerImage]
/// assets. Used with camera frames until ARCore image tracking is embedded.
class LogoMatcherService {
  LogoMatcherService();

  final Map<String, BigInt> _hashesByEquipoId = {};
  final Map<String, BigInt> _hashesByMarcadorId = {};
  bool _equiposLoaded = false;

  Future<void> ensureEquipoLogosLoaded() async {
    if (_equiposLoaded) return;
    for (final entry in AppAssets.teamLogoById.entries) {
      final bytes = await rootBundle.load(entry.value);
      final hash = averageHash(bytes.buffer.asUint8List());
      if (hash != null) {
        _hashesByEquipoId[entry.key] = hash;
      }
    }
    _equiposLoaded = true;
  }

  Future<void> loadMarcadores(List<Marcador> marcadores) async {
    _hashesByMarcadorId.clear();
    for (final marcador in marcadores) {
      final bytes = await rootBundle.load(marcador.markerImage);
      final hash = averageHash(bytes.buffer.asUint8List());
      if (hash != null) {
        _hashesByMarcadorId[marcador.id] = hash;
      }
    }
  }

  Future<String?> matchBytes(
    Uint8List bytes, {
    int maxHammingDistance = 12,
  }) async {
    await ensureEquipoLogosLoaded();
    return _bestMatch(
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
    return _bestMatch(
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

  String? _bestMatch(
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

  int get catalogSize => _hashesByEquipoId.length;
  int get marcadorCatalogSize => _hashesByMarcadorId.length;
}
