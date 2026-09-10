import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// On-device preview filters for the video archive (Article VII / D-05).
///
/// Allowed families only. Do not add blanco y negro, escala de grises,
/// sepia, exposición, or invert — those are forbidden.
enum FiltroPartido {
  ninguno,
  desenfoque,
  pixelado,
  termica,
  ajusteColor,
  suavizado,
  pasteles,
  altaSaturacion,
}

abstract final class FilterEngine {
  static const List<FiltroPartido> familias = [
    FiltroPartido.desenfoque,
    FiltroPartido.pixelado,
    FiltroPartido.termica,
    FiltroPartido.ajusteColor,
  ];

  static const List<FiltroPartido> personalizados = [
    FiltroPartido.suavizado,
    FiltroPartido.pasteles,
    FiltroPartido.altaSaturacion,
  ];

  static String etiqueta(FiltroPartido filtro) {
    return switch (filtro) {
      FiltroPartido.ninguno => 'Original',
      FiltroPartido.desenfoque => 'Desenfoque',
      FiltroPartido.pixelado => 'Pixelado',
      FiltroPartido.termica => 'Cámara térmica',
      FiltroPartido.ajusteColor => 'Ajuste de color',
      FiltroPartido.suavizado => 'Suavizado',
      FiltroPartido.pasteles => 'Pasteles',
      FiltroPartido.altaSaturacion => 'Alta saturación',
    };
  }

  /// Wraps [child] so the preview runs on the compositor, not a server.
  static Widget aplicar(FiltroPartido filtro, Widget child) {
    return switch (filtro) {
      FiltroPartido.ninguno => child,
      FiltroPartido.desenfoque => ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 2.4, sigmaY: 2.4),
          child: child,
        ),
      FiltroPartido.pixelado => _Pixelado(child: child),
      FiltroPartido.termica => ColorFiltered(
          colorFilter: const ColorFilter.matrix(_termica),
          child: child,
        ),
      FiltroPartido.ajusteColor => ColorFiltered(
          colorFilter: const ColorFilter.matrix(_luzEstadio),
          child: child,
        ),
      FiltroPartido.suavizado => ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 0.9, sigmaY: 0.9),
          child: child,
        ),
      FiltroPartido.pasteles => ColorFiltered(
          colorFilter: const ColorFilter.matrix(_pasteles),
          child: child,
        ),
      FiltroPartido.altaSaturacion => ColorFiltered(
          colorFilter: const ColorFilter.matrix(_altaSaturacion),
          child: child,
        ),
    };
  }
}

/// Nearest-neighbor downsample so the preview reads as blocks, not a tint.
class _Pixelado extends StatelessWidget {
  const _Pixelado({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: 42,
          height: 24,
          child: Transform(
            alignment: Alignment.center,
            filterQuality: FilterQuality.none,
            transform: Matrix4.identity(),
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 420,
                height: 240,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Heat-camera cast: red/amber highlights, cool blue lift. Not a gray map.
const List<double> _termica = <double>[
  1.55, 0.25, 0.00, 0, 8,
  0.15, 0.45, 0.05, 0, 0,
  0.00, 0.10, 0.70, 0, 28,
  0, 0, 0, 1, 0,
];

// Stadium-light warmth. Keeps chroma; not a brown wash.
const List<double> _luzEstadio = <double>[
  1.18, 0.06, 0.00, 0, 10,
  0.02, 1.02, 0.00, 0, 0,
  0.00, 0.00, 0.72, 0, 0,
  0, 0, 0, 1, 0,
];

// Lifted, washed color. Saturation stays above a gray map.
const List<double> _pasteles = <double>[
  0.70, 0.10, 0.06, 0, 42,
  0.06, 0.72, 0.08, 0, 46,
  0.08, 0.08, 0.68, 0, 50,
  0, 0, 0, 1, 0,
];

// Standard saturation matrix at 1.85. A factor of 0 would be gray — do not use it.
const List<double> _altaSaturacion = <double>[
  1.6695, -0.6080, -0.0614, 0, 0,
  -0.1805, 1.2420, -0.0614, 0, 0,
  -0.1805, -0.6080, 1.7886, 0, 0,
  0, 0, 0, 1, 0,
];
