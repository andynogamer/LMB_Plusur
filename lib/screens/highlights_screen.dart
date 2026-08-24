import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/demo_highlights.dart';
import '../models/equipo_model.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/highlight_video_player.dart';
import '../widgets/screen_background.dart';

class HighlightsScreen extends StatefulWidget {
  const HighlightsScreen({
    super.key,
    required this.equipo,
  });

  final Equipo equipo;

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  int? _playingIndex;

  @override
  Widget build(BuildContext context) {
    final highlights = DemoHighlights.items;

    return Scaffold(
      body: ScreenBackground(
        child: Column(
          children: [
            AppHeader(
              title: widget.equipo.displayName,
              subtitle: 'Highlights de demostración',
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: highlights.length,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final highlight = highlights[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        highlight.title.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      HighlightVideoPlayer(
                        url: highlight.videoUrl!,
                        isActive: _playingIndex == index,
                        onPlay: () => setState(() => _playingIndex = index),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
