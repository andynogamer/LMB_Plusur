import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/utils/youtube_id.dart';

void main() {
  test('lee el id de una URL de watch', () {
    expect(
      youtubeVideoId('https://www.youtube.com/watch?v=TtD989lgRtA'),
      'TtD989lgRtA',
    );
    expect(
      youtubeVideoId('http://www.youtube.com/watch?v=tnUJwIMK1fY'),
      'tnUJwIMK1fY',
    );
  });

  test('rechaza URLs que no son de YouTube', () {
    expect(
      youtubeVideoId(
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      ),
      isNull,
    );
  });
}
