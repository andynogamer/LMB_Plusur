import 'dart:math' as math;

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

  /// Lower is closer (combined hue + structure score, 0-100).
  final String equipoId;
  final int distance;
  final bool accepted;
}

/// Image recognition helper (SP-01 / US-06).
///
/// Asset self-checks use average-hash against [AppAssets.teamLogoById].
/// Camera frames cannot use that: a photo of a printed logo is not an 8x8
/// brightness clone of the PNG, and grayscale MAD collapses onto El Águila
/// (a nearly flat red field).
///
/// Camera matching instead:
/// 1. Crops to the logo-like region (center scales + color/edge box).
/// 2. Scores **hue of saturated pixels** (team color) plus **dHash** of the
///    glyph (shape). A red wall cannot beat Águila's "V".
/// 3. Accepts only when the winner is clearly ahead of the runner-up.
class LogoMatcherService {
  LogoMatcherService();

  final Map<String, BigInt> _hashesByEquipoId = {};
  final Map<String, BigInt> _hashesByMarcadorId = {};
  final Map<String, _LogoSig> _sigsByEquipoId = {};
  bool _equiposLoaded = false;

  Future<void> ensureEquipoLogosLoaded() async {
    if (_equiposLoaded) return;
    for (final entry in AppAssets.teamLogoById.entries) {
      final bytes = (await rootBundle.load(entry.value)).buffer.asUint8List();
      final hash = averageHash(bytes);
      if (hash != null) _hashesByEquipoId[entry.key] = hash;
      final sig = _sigFromBytes(bytes);
      if (sig != null) _sigsByEquipoId[entry.key] = sig;
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

  /// Camera JPEG/PNG → stable [Equipo.id]. [preferEquipoId] only breaks
  /// exact ties so "Abrir experiencia AR" cannot force the wrong club.
  Future<CameraLogoMatch?> matchFromCamera(
    Uint8List bytes, {
    String? preferEquipoId,
  }) async {
    await ensureEquipoLogosLoaded();
    final decoded = img.decodeImage(bytes);
    if (decoded == null || _sigsByEquipoId.isEmpty) return null;
    final oriented = _workingSize(img.bakeOrientation(decoded));

    CameraLogoMatch? bestAccepted;
    CameraLogoMatch? bestRejected;

    for (final view in _probeViews(oriented)) {
      final probe = _sigFromImage(view);
      if (probe == null) continue;
      final ranked = _rankByScore(probe);
      if (ranked.isEmpty) continue;

      var top = ranked.first;
      if (preferEquipoId != null) {
        for (final row in ranked) {
          if (row.id == preferEquipoId && row.score == top.score) {
            top = row;
            break;
          }
        }
      }

      final second = ranked.length > 1 ? ranked[1].score : 100;
      final margin = second - top.score;
      final catalog = _sigsByEquipoId[top.id];
      final accepted = catalog != null &&
          _accept(
            probe: probe,
            catalog: catalog,
            score: top.score,
            margin: margin,
          );

      final candidate = CameraLogoMatch(
        equipoId: top.id,
        distance: top.score,
        accepted: accepted,
      );
      debugPrint(
        'LMB_SCAN top=${top.id}:${top.score} '
        'second=${ranked.length > 1 ? ranked[1].id : "-"}:$second '
        'margin=$margin sat=${probe.satRatio} edge=${probe.edgeEnergy} '
        'accepted=$accepted',
      );

      if (accepted) {
        if (bestAccepted == null || candidate.distance < bestAccepted.distance) {
          bestAccepted = candidate;
        }
      } else if (bestRejected == null ||
          candidate.distance < bestRejected.distance) {
        bestRejected = candidate;
      }
    }

    return bestAccepted ?? bestRejected;
  }

  bool _accept({
    required _LogoSig probe,
    required _LogoSig catalog,
    required int score,
    required int margin,
  }) {
    if (score > 28) return false;
    if (margin < 3) return false;
    if (margin < 5 && score > 22) return false;
    if (probe.chromatic && catalog.chromatic) {
      final hue = _hueL1(probe.hueHist, catalog.hueHist);
      if (hue > 0.55) return false;
    }
    if (probe.edgeEnergy < 5 && catalog.edgeEnergy >= 10) return false;
    if (catalog.edgeEnergy >= 10 &&
        probe.edgeEnergy < (catalog.edgeEnergy * 0.32).round()) {
      return false;
    }
    if (catalog.satRatio >= 50 && probe.satRatio < 22) return false;
    if (probe.satRatio >= 50 && catalog.satRatio < 15) return false;
    return true;
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

  List<({String id, int score})> _rankByScore(_LogoSig probe) {
    final ranked = <({String id, int score})>[];
    _sigsByEquipoId.forEach((id, sig) {
      ranked.add((id: id, score: probe.distanceTo(sig)));
    });
    ranked.sort((a, b) => a.score.compareTo(b.score));
    return ranked;
  }

  Iterable<img.Image> _probeViews(img.Image oriented) sync* {
    yield oriented;
    for (final crop in const [0.84, 0.66, 0.48]) {
      yield _centerCrop(oriented, crop);
    }
    final sat = _regionCrop(oriented, mode: _RegionMode.saturated);
    if (sat != null) yield sat;
    final edge = _regionCrop(oriented, mode: _RegionMode.edges);
    if (edge != null) yield edge;
  }

  _LogoSig? _sigFromBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    return _sigFromImage(_workingSize(img.bakeOrientation(decoded)));
  }

  static _LogoSig? _sigFromImage(img.Image source) {
    final flat = _flatten(source);
    final tight = _tightContent(flat);
    final satRatio = _satRatio(flat);
    return _LogoSig(
      hashFull: _dHash(flat),
      hashTight: _dHash(tight),
      shape: _normGrid(tight),
      hueHist: _hueHist(flat),
      satRatio: satRatio,
      aspect: ((tight.width * 10) / tight.height).round().clamp(3, 80),
      edgeEnergy: _LogoSig.edgeEnergyOf(_lumaGrid(tight, 16)),
      chromatic: satRatio >= 12,
    );
  }

  static img.Image _flatten(img.Image source) {
    if (source.numChannels < 4) return source;
    final out = img.Image(width: source.width, height: source.height);
    img.fill(out, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(out, source);
    return out;
  }

  static img.Image _workingSize(img.Image source) {
    const maxSide = 512;
    if (source.width <= maxSide && source.height <= maxSide) return source;
    if (source.width >= source.height) {
      return img.copyResize(
        source,
        width: maxSide,
        interpolation: img.Interpolation.linear,
      );
    }
    return img.copyResize(
      source,
      height: maxSide,
      interpolation: img.Interpolation.linear,
    );
  }

  static img.Image _centerCrop(img.Image image, double crop) {
    final width = (image.width * crop).round().clamp(16, image.width);
    final height = (image.height * crop).round().clamp(16, image.height);
    final x = ((image.width - width) / 2).round();
    final y = ((image.height - height) / 2).round();
    return img.copyCrop(image, x: x, y: y, width: width, height: height);
  }

  static img.Image _tightContent(img.Image source) {
    final sat = _regionCrop(source, mode: _RegionMode.saturated);
    if (sat != null) return sat;
    final edge = _regionCrop(source, mode: _RegionMode.edges);
    if (edge != null) return edge;
    try {
      final box = img.findTrim(
        source,
        mode: img.TrimMode.topLeftColor,
        fuzzy: 0.14,
        padding: 6,
      );
      final w = box[2];
      final h = box[3];
      if (w >= 16 &&
          h >= 16 &&
          w * h < source.width * source.height * 0.94) {
        return img.copyCrop(
          source,
          x: box[0],
          y: box[1],
          width: w,
          height: h,
        );
      }
    } catch (_) {}
    return source;
  }

  static img.Image? _regionCrop(img.Image source, {required _RegionMode mode}) {
    const analysis = 64;
    final small = img.copyResize(source, width: analysis);
    final sw = small.width;
    final sh = small.height;
    var minX = sw;
    var minY = sh;
    var maxX = 0;
    var maxY = 0;
    var count = 0;

    for (var y = 1; y < sh - 1; y++) {
      for (var x = 1; x < sw - 1; x++) {
        final p = small.getPixel(x, y);
        final interesting = mode == _RegionMode.saturated
            ? _isSaturated(p)
            : _isEdge(small, x, y);
        if (!interesting) continue;
        count++;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }

    if (count < 8 || maxX <= minX || maxY <= minY) return null;
    final scaleX = source.width / sw;
    final scaleY = source.height / sh;
    var x = (minX * scaleX).floor();
    var y = (minY * scaleY).floor();
    var w = ((maxX - minX + 1) * scaleX).ceil();
    var h = ((maxY - minY + 1) * scaleY).ceil();
    final padX = (w * 0.12).round();
    final padY = (h * 0.12).round();
    x = (x - padX).clamp(0, source.width - 16);
    y = (y - padY).clamp(0, source.height - 16);
    w = (w + padX * 2).clamp(16, source.width - x);
    h = (h + padY * 2).clamp(16, source.height - y);
    final area = w * h;
    final full = source.width * source.height;
    if (area < full * 0.012 || area > full * 0.97) return null;
    return img.copyCrop(source, x: x, y: y, width: w, height: h);
  }

  static bool _isSaturated(img.Pixel p) {
    final hsv = _hsv(p);
    return hsv.s > 0.28 && hsv.v > 0.16 && hsv.v < 0.97;
  }

  static bool _isEdge(img.Image image, int x, int y) {
    final g = _luma(image.getPixel(x, y));
    final r = _luma(image.getPixel(x + 1, y));
    final d = _luma(image.getPixel(x, y + 1));
    return (g - r).abs() > 18 || (g - d).abs() > 18;
  }

  static List<double> _hueHist(img.Image image) {
    final bins = List<double>.filled(12, 0);
    var n = 0;
    for (var y = 0; y < image.height; y += 2) {
      for (var x = 0; x < image.width; x += 2) {
        final hsv = _hsv(image.getPixel(x, y));
        if (hsv.s < 0.22 || hsv.v < 0.15 || hsv.v > 0.98) continue;
        final bin = ((hsv.h / 30).floor()) % 12;
        bins[bin] += 1;
        n++;
      }
    }
    if (n == 0) return bins;
    for (var i = 0; i < bins.length; i++) {
      bins[i] /= n;
    }
    return bins;
  }

  static int _satRatio(img.Image image) {
    var sat = 0;
    var n = 0;
    for (var y = 0; y < image.height; y += 2) {
      for (var x = 0; x < image.width; x += 2) {
        n++;
        if (_isSaturated(image.getPixel(x, y))) sat++;
      }
    }
    if (n == 0) return 0;
    return ((sat / n) * 100).round();
  }

  static BigInt _dHash(img.Image image) {
    final small = img.copyResize(
      image,
      width: 17,
      height: 16,
      interpolation: img.Interpolation.average,
    );
    var hash = BigInt.zero;
    var bit = 0;
    for (var y = 0; y < 16; y++) {
      for (var x = 0; x < 16; x++) {
        final a = _luma(small.getPixel(x, y));
        final b = _luma(small.getPixel(x + 1, y));
        if (a < b) hash |= (BigInt.one << bit);
        bit++;
      }
    }
    return hash;
  }

  static List<int> _normGrid(img.Image image) {
    final gray = _lumaGrid(image, 16);
    final mean = gray.reduce((a, b) => a + b) / gray.length;
    var varSum = 0.0;
    for (final g in gray) {
      final d = g - mean;
      varSum += d * d;
    }
    final std = math.sqrt(varSum / gray.length).clamp(8.0, 80.0);
    return [
      for (final g in gray)
        ((g - mean) / std * 40 + 128).round().clamp(0, 255),
    ];
  }

  static int _meanAbs(List<int> a, List<int> b) {
    final n = math.min(a.length, b.length);
    if (n == 0) return 255;
    var sum = 0;
    for (var i = 0; i < n; i++) {
      sum += (a[i] - b[i]).abs();
    }
    return (sum / n).round();
  }

  static List<int> _lumaGrid(img.Image image, int size) {
    final small = img.copyResize(
      image,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );
    final out = <int>[];
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        out.add(_luma(small.getPixel(x, y)));
      }
    }
    return out;
  }

  static ({double h, double s, double v}) _hsv(img.Pixel p) {
    final r = p.r / 255.0;
    final g = p.g / 255.0;
    final b = p.b / 255.0;
    final maxc = math.max(r, math.max(g, b));
    final minc = math.min(r, math.min(g, b));
    final d = maxc - minc;
    var h = 0.0;
    if (d > 1e-6) {
      if (maxc == r) {
        h = (g - b) / d;
      } else if (maxc == g) {
        h = (b - r) / d + 2;
      } else {
        h = (r - g) / d + 4;
      }
      h *= 60;
      if (h < 0) h += 360;
    }
    final s = maxc == 0 ? 0.0 : d / maxc;
    return (h: h, s: s, v: maxc);
  }

  static int _luma(img.Pixel p) =>
      ((p.r * 3 + p.g * 6 + p.b) / 10).round().clamp(0, 255);

  static double _hueL1(List<double> a, List<double> b) {
    var sum = 0.0;
    final n = math.min(a.length, b.length);
    for (var i = 0; i < n; i++) {
      sum += (a[i] - b[i]).abs();
    }
    return sum / 2.0;
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

enum _RegionMode { saturated, edges }

class _LogoSig {
  _LogoSig({
    required this.hashFull,
    required this.hashTight,
    required this.shape,
    required this.hueHist,
    required this.satRatio,
    required this.aspect,
    required this.edgeEnergy,
    required this.chromatic,
  });

  final BigInt hashFull;
  final BigInt hashTight;
  final List<int> shape;
  final List<double> hueHist;
  final int satRatio;
  final int aspect;
  final int edgeEnergy;
  final bool chromatic;

  int distanceTo(_LogoSig other) {
    final hash = _minHash(other).clamp(0, 256);
    final hashScore = (hash / 256) * 100;
    final shapeScore = (LogoMatcherService._meanAbs(shape, other.shape) / 2.55)
        .clamp(0, 100);
    final hue = LogoMatcherService._hueL1(hueHist, other.hueHist);
    final hueScore = hue * 100;
    final sat = (satRatio - other.satRatio).abs().toDouble();
    final energy = (edgeEnergy - other.edgeEnergy).abs().clamp(0, 100);
    final aspectScore =
        ((aspect - other.aspect).abs() * 2.4).clamp(0, 100).toDouble();
    var score = hashScore * 0.22 +
        shapeScore * 0.34 +
        hueScore * 0.24 +
        aspectScore * 0.12 +
        sat * 0.05 +
        energy * 0.03;
    if (chromatic && other.chromatic && hue > 0.48) {
      score += 28;
    }
    return score.round().clamp(0, 100);
  }

  int _minHash(_LogoSig other) {
    final a = LogoMatcherService.hammingDistance(hashFull, other.hashFull);
    final b = LogoMatcherService.hammingDistance(hashTight, other.hashTight);
    final c = LogoMatcherService.hammingDistance(hashTight, other.hashFull);
    final d = LogoMatcherService.hammingDistance(hashFull, other.hashTight);
    return math.min(a, math.min(b, math.min(c, d)));
  }

  static int edgeEnergyOf(List<int> gray) {
    const size = 16;
    if (gray.length != size * size) return 0;
    var sum = 0;
    var count = 0;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size - 1; x++) {
        final i = y * size + x;
        sum += (gray[i + 1] - gray[i]).abs();
        count++;
      }
    }
    for (var y = 0; y < size - 1; y++) {
      for (var x = 0; x < size; x++) {
        final i = y * size + x;
        sum += (gray[i + size] - gray[i]).abs();
        count++;
      }
    }
    if (count == 0) return 0;
    return (sum / count).round();
  }
}
