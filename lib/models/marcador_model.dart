/// Content type of a printable AR marker (D-20).
///
/// JSON values are the enum names verbatim — do not invent a second vocabulary.
enum TipoMarcador {
  estadio,
  trofeo,
  pelota,
  jugador;

  static TipoMarcador fromJson(String value) {
    for (final tipo in TipoMarcador.values) {
      if (tipo.name == value) return tipo;
    }
    throw FormatException('tipo de marcador desconocido: $value');
  }
}

/// One scannable marker and the content it unlocks.
///
/// Identity is [id]. The reference-image filename stem MUST equal [id]
/// (Article VI.4). Placeholder [modelAsset] paths may not exist yet.
class Marcador {
  const Marcador({
    required this.id,
    required this.equipoId,
    required this.tipo,
    required this.titulo,
    required this.infoTexto,
    required this.markerImage,
    required this.modelAsset,
    required this.anchoMetros,
    this.videoUrl,
    this.animaciones = const [],
  });

  final String id;
  final String equipoId;
  final TipoMarcador tipo;
  final String titulo;
  final String infoTexto;

  /// Asset path of the reference image, e.g. `assets/markers/marcador_….png`.
  final String markerImage;

  /// Placeholder GLB path. The file need not exist until AR-06.
  final String modelAsset;

  /// Printed physical width in metres. Improves ARCore pose; not yet measured
  /// from a physical print (see `docs/ar-marker-guide.md` §6).
  final double anchoMetros;

  final String? videoUrl;
  final List<String> animaciones;

  factory Marcador.fromJson(Map<String, dynamic> json) {
    return Marcador(
      id: json['id'] as String,
      equipoId: json['equipoId'] as String,
      tipo: TipoMarcador.fromJson(json['tipo'] as String),
      titulo: json['titulo'] as String,
      infoTexto: json['infoTexto'] as String,
      markerImage: json['markerImage'] as String,
      modelAsset: json['modelAsset'] as String,
      anchoMetros: (json['anchoMetros'] as num).toDouble(),
      videoUrl: json['videoUrl'] as String?,
      animaciones: (json['animaciones'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(growable: false),
    );
  }
}
