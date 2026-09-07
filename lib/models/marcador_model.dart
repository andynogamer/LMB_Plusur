enum TipoMarcador {
  estadio,
  trofeo,
  pelota,
  jugador;

  static TipoMarcador fromJson(String value) {
    return TipoMarcador.values.firstWhere(
      (tipo) => tipo.name == value,
      orElse: () => TipoMarcador.pelota,
    );
  }
}

/// Scannable AR element with team-linked content (US-05 / grading ?3 markers).
class Marcador {
  const Marcador({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.infoTexto,
    required this.markerImage,
    required this.modelAsset,
    required this.animaciones,
    this.equipoId,
    this.videoUrl,
  });

  final String id;
  final String? equipoId;
  final TipoMarcador tipo;
  final String titulo;
  final String infoTexto;
  final String markerImage;
  final String modelAsset;
  final String? videoUrl;
  final List<String> animaciones;

  factory Marcador.fromJson(Map<String, dynamic> json) {
    return Marcador(
      id: json['id'] as String,
      equipoId: json['equipoId'] as String?,
      tipo: TipoMarcador.fromJson(json['tipo'] as String),
      titulo: json['titulo'] as String,
      infoTexto: json['infoTexto'] as String,
      markerImage: json['markerImage'] as String,
      modelAsset: json['modelAsset'] as String,
      videoUrl: json['videoUrl'] as String?,
      animaciones: (json['animaciones'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'equipoId': equipoId,
        'tipo': tipo.name,
        'titulo': titulo,
        'infoTexto': infoTexto,
        'markerImage': markerImage,
        'modelAsset': modelAsset,
        'videoUrl': videoUrl,
        'animaciones': animaciones,
      };
}
