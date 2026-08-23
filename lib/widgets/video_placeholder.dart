import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Placeholder visual del reproductor. `video_player` se usará cuando
/// existan URLs reales de highlights.
class VideoPlaceholder extends StatelessWidget {
  const VideoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.videoPlaceholder,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Stack(
          children: [
            Center(
              child: Icon(
                Icons.play_circle_fill,
                color: AppColors.white,
                size: 64,
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Row(
                children: [
                  Icon(Icons.play_arrow, color: AppColors.white, size: 22),
                  SizedBox(width: 8),
                  Icon(Icons.volume_up, color: AppColors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                      child: LinearProgressIndicator(
                        value: 0.28,
                        minHeight: 4,
                        color: Color(0xFFE53935),
                        backgroundColor: Color(0x66FFFFFF),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.fullscreen, color: AppColors.white, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
