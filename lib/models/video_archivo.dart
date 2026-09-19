import '../utils/youtube_id.dart';

/// One entry in the local video archive. JSON keys stay Spanish.
class VideoArchivo {
  const VideoArchivo({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.url,
    this.equipoId,
  });

  final String id;
  final String titulo;
  final String descripcion;
  final String url;

  /// Canonical club id from `assets/data.json`, or null for a Zona Sur clip.
  final String? equipoId;

  String? get miniaturaUrl {
    final videoId = youtubeVideoId(url);
    return videoId == null
        ? null
        : 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
  }

  factory VideoArchivo.fromJson(Map<String, dynamic> json) {
    return VideoArchivo(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      url: json['url'] as String,
      equipoId: json['equipoId'] as String?,
    );
  }
}
