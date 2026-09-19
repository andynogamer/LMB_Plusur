import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/models/video_archivo.dart';

void main() {
  test('construye la miniatura de YouTube desde el catálogo', () {
    const video = VideoArchivo(
      id: 'video',
      titulo: 'Juego',
      descripcion: 'Resumen',
      url: 'https://www.youtube.com/watch?v=TtD989lgRtA',
    );

    expect(
      video.miniaturaUrl,
      'https://i.ytimg.com/vi/TtD989lgRtA/hqdefault.jpg',
    );
  });

  test('no inventa miniaturas para URLs no compatibles', () {
    const video = VideoArchivo(
      id: 'video',
      titulo: 'Juego',
      descripcion: 'Resumen',
      url: 'https://example.com/video.mp4',
    );

    expect(video.miniaturaUrl, isNull);
  });
}
