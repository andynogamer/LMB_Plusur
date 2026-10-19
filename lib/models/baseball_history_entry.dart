class BaseballHistoryEntry {
  const BaseballHistoryEntry({
    required this.id,
    required this.periodo,
    required this.titulo,
    required this.resumen,
    required this.detalle,
    required this.imagenUrl,
    required this.imagenCredito,
    required this.imagenFuenteUrl,
    required this.licenciaImagen,
    required this.licenciaImagenUrl,
    required this.fuenteHistoricaUrl,
  });

  final String id;
  final String periodo;
  final String titulo;
  final String resumen;
  final String detalle;
  final String imagenUrl;
  final String imagenCredito;
  final String imagenFuenteUrl;
  final String licenciaImagen;
  final String licenciaImagenUrl;
  final String fuenteHistoricaUrl;

  factory BaseballHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BaseballHistoryEntry(
      id: json['id'] as String,
      periodo: json['periodo'] as String,
      titulo: json['titulo'] as String,
      resumen: json['resumen'] as String,
      detalle: json['detalle'] as String,
      imagenUrl: json['imagenUrl'] as String,
      imagenCredito: json['imagenCredito'] as String,
      imagenFuenteUrl: json['imagenFuenteUrl'] as String,
      licenciaImagen: json['licenciaImagen'] as String,
      licenciaImagenUrl: json['licenciaImagenUrl'] as String,
      fuenteHistoricaUrl: json['fuenteHistoricaUrl'] as String,
    );
  }
}
