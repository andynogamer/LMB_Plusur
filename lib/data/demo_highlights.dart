import '../models/highlight.dart';

abstract final class DemoHighlights {
  static const List<Highlight> items = [
    Highlight(
      title: 'HOME RUN!!!',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    ),
    Highlight(
      title: 'SAFE!!!',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    ),
    Highlight(
      title: 'PONCHE CLAVE',
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    ),
  ];
}
