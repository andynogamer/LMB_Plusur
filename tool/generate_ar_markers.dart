import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:lmb_plusur/theme/app_assets.dart';

/// Builds ARCore-friendly tracking images in `assets/markers/`.
///
/// Baseball wordmarks on white are too similar; Guerreros (white on black)
/// becomes an attractor. Each output is a unique high-feature card with the
/// team logo in the center. Print or show that card — not a generic merch logo.
///
/// Run from the repo root:
/// `dart run tool/generate_ar_markers.dart`
void main() {
  const size = 1024;
  const border = 112;
  final outDir = Directory('assets/markers');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  for (final old in outDir.listSync()) {
    if (old is File) old.deleteSync();
  }

  for (final entry in AppAssets.teamLogoById.entries) {
    final source = File(entry.value);
    if (!source.existsSync()) {
      stderr.writeln('Missing logo: ${entry.value}');
      exitCode = 1;
      continue;
    }

    final decoded = img.decodeImage(source.readAsBytesSync());
    if (decoded == null) {
      stderr.writeln('Could not decode: ${entry.value}');
      exitCode = 1;
      continue;
    }

    final card = _buildCard(
      equipoId: entry.key,
      logo: decoded,
      size: size,
      border: border,
    );
    final outPath = 'assets/markers/${entry.key}.png';
    File(outPath).writeAsBytesSync(img.encodePng(card, level: 6));
    stdout.writeln('Wrote $outPath (${card.width}x${card.height})');
  }
}

img.Image _buildCard({
  required String equipoId,
  required img.Image logo,
  required int size,
  required int border,
}) {
  final seed = equipoId.codeUnits.fold<int>(0, (a, b) => (a * 33 + b) & 0x7fffffff);
  final accent = _accentFor(equipoId);
  final black = img.ColorRgb8(8, 8, 8);
  final white = img.ColorRgb8(255, 255, 255);
  final canvas = img.Image(width: size, height: size);
  img.fill(canvas, color: white);

  const cell = 16;
  for (var y = 0; y < size; y += cell) {
    for (var x = 0; x < size; x += cell) {
      final inInner = x >= border &&
          y >= border &&
          x < size - border &&
          y < size - border;
      if (inInner) continue;
      final bit = _cellBit(seed, x ~/ cell, y ~/ cell);
      final color = bit ? black : accent;
      img.fillRect(
        canvas,
        x1: x,
        y1: y,
        x2: math.min(x + cell - 1, size - 1),
        y2: math.min(y + cell - 1, size - 1),
        color: color,
      );
    }
  }

  img.fillRect(
    canvas,
    x1: border,
    y1: border,
    x2: size - border - 1,
    y2: size - border - 1,
    color: white,
  );

  const finder = 7;
  const module = 12;
  _drawFinder(canvas, border + 8, border + 8, finder, module, black, white);
  _drawFinder(
    canvas,
    size - border - 8 - finder * module,
    border + 8,
    finder,
    module,
    black,
    white,
  );
  _drawFinder(
    canvas,
    border + 8,
    size - border - 8 - finder * module,
    finder,
    module,
    black,
    white,
  );
  _drawUniqueFinder(
    canvas,
    size - border - 8 - finder * module,
    size - border - 8 - finder * module,
    finder,
    module,
    seed,
    accent,
    black,
    white,
  );

  _drawIdentityBlocks(
    canvas: canvas,
    seed: seed,
    size: size,
    border: border,
    accent: accent,
    black: black,
  );

  var prepared = _prepareLogo(logo);
  const pad = 36;
  final maxW = size - 2 * border - pad * 2;
  final maxH = size - 2 * border - pad * 2 - 48;
  final scale = math.min(maxW / prepared.width, maxH / prepared.height);
  prepared = img.copyResize(
    prepared,
    width: math.max(64, (prepared.width * scale).round()),
    height: math.max(64, (prepared.height * scale).round()),
    interpolation: img.Interpolation.cubic,
  );

  final dstX = (size - prepared.width) ~/ 2;
  final dstY = border + pad + ((maxH - prepared.height) ~/ 2);
  img.compositeImage(canvas, prepared, dstX: dstX, dstY: dstY);
  return canvas;
}

img.Image _prepareLogo(img.Image logo) {
  var work = logo.clone();
  final corner = work.getPixel(0, 0);
  final darkBg = corner.luminance < 48;
  if (!darkBg) {
    work = img.trim(work, mode: img.TrimMode.topLeftColor);
  }
  if (work.width < 8 || work.height < 8) return logo;
  return work;
}

void _drawFinder(
  img.Image canvas,
  int originX,
  int originY,
  int modules,
  int module,
  img.Color black,
  img.Color white,
) {
  final size = modules * module;
  img.fillRect(
    canvas,
    x1: originX,
    y1: originY,
    x2: originX + size - 1,
    y2: originY + size - 1,
    color: black,
  );
  img.fillRect(
    canvas,
    x1: originX + module,
    y1: originY + module,
    x2: originX + size - module - 1,
    y2: originY + size - module - 1,
    color: white,
  );
  img.fillRect(
    canvas,
    x1: originX + module * 2,
    y1: originY + module * 2,
    x2: originX + size - module * 2 - 1,
    y2: originY + size - module * 2 - 1,
    color: black,
  );
}

void _drawUniqueFinder(
  img.Image canvas,
  int originX,
  int originY,
  int modules,
  int module,
  int seed,
  img.Color accent,
  img.Color black,
  img.Color white,
) {
  _drawFinder(canvas, originX, originY, modules, module, black, white);
  for (var j = 2; j < modules - 2; j++) {
    for (var i = 2; i < modules - 2; i++) {
      final on = _cellBit(seed, i + 17, j + 23);
      img.fillRect(
        canvas,
        x1: originX + i * module,
        y1: originY + j * module,
        x2: originX + (i + 1) * module - 1,
        y2: originY + (j + 1) * module - 1,
        color: on ? accent : black,
      );
    }
  }
}

void _drawIdentityBlocks({
  required img.Image canvas,
  required int seed,
  required int size,
  required int border,
  required img.Color accent,
  required img.Color black,
}) {
  final white = img.ColorRgb8(255, 255, 255);
  final count = 3 + (seed % 4);
  final blockH = 40;
  final top = (border - blockH) ~/ 2;
  var x = border + 16;
  for (var i = 0; i < count; i++) {
    final w = 28 + ((seed >> (i * 3)) & 31);
    if (x + w >= size - border - 16) break;
    img.fillRect(
      canvas,
      x1: x,
      y1: top,
      x2: x + w,
      y2: top + blockH,
      color: i.isEven ? white : black,
    );
    img.fillRect(
      canvas,
      x1: x + 4,
      y1: top + 4,
      x2: x + w - 4,
      y2: top + blockH - 4,
      color: i.isEven ? accent : white,
    );
    x += w + 10;
  }
}

bool _cellBit(int seed, int x, int y) {
  var n = seed ^ (x * 73856093) ^ (y * 19349663);
  n = (n ^ (n << 13)) & 0x7fffffff;
  n = (n ^ (n >> 17)) & 0x7fffffff;
  n = (n ^ (n << 5)) & 0x7fffffff;
  return (n & 1) == 1;
}

img.ColorRgb8 _accentFor(String equipoId) {
  switch (equipoId) {
    case 'diablos_rojos':
      return img.ColorRgb8(196, 18, 48);
    case 'bravos_leon':
      return img.ColorRgb8(0, 122, 61);
    case 'conspiradores_queretaro':
      return img.ColorRgb8(118, 32, 72);
    case 'aguila_veracruz':
      return img.ColorRgb8(220, 40, 40);
    case 'guerreros_oaxaca':
      return img.ColorRgb8(201, 162, 39);
    case 'leones_yucatan':
      return img.ColorRgb8(16, 58, 122);
    case 'olmecas_tabasco':
      return img.ColorRgb8(34, 98, 48);
    case 'pericos_puebla':
      return img.ColorRgb8(46, 140, 58);
    case 'piratas_campeche':
      return img.ColorRgb8(176, 28, 36);
    case 'tigres_quintana_roo':
      return img.ColorRgb8(18, 40, 92);
    default:
      return img.ColorRgb8(40, 40, 40);
  }
}
