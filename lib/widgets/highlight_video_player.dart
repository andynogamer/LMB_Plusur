import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/filter_engine.dart';
import '../theme/app_colors.dart';

class HighlightVideoPlayer extends StatefulWidget {
  const HighlightVideoPlayer({
    super.key,
    required this.url,
    this.isActive = false,
    this.onPlay,
    this.filtro = FiltroPartido.ninguno,
  });

  final String url;
  final bool isActive;
  final VoidCallback? onPlay;
  final FiltroPartido filtro;

  @override
  State<HighlightVideoPlayer> createState() => _HighlightVideoPlayerState();
}

class _HighlightVideoPlayerState extends State<HighlightVideoPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      controller.setLooping(true);
      // Errors only — do not setState on every playback tick (rebuilds filters).
      controller.addListener(_onControllerTick);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onControllerTick() {
    final controller = _controller;
    if (!mounted || controller == null) return;
    if (controller.value.hasError && !_failed) {
      setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(HighlightVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive) {
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    controller?.removeListener(_onControllerTick);
    controller?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      widget.onPlay?.call();
      await controller.play();
    }
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    if (controller == null) return;
    _muted = !_muted;
    await controller.setVolume(_muted ? 0 : 1);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_failed) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_outlined, color: AppColors.muted, size: 36),
            SizedBox(height: 10),
            Text(
              'No se pudo reproducir este video. Revisa tu conexión e inténtalo de nuevo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.button, strokeWidth: 2.4),
      );
    }

    // Video + filter stay outside the tick rebuild; chrome listens separately.
    return Stack(
      fit: StackFit.expand,
      children: [
        FilterEngine.aplicar(
          widget.filtro,
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Color(0x8C000000),
              ],
              stops: [0.55, 1],
            ),
          ),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => _Chrome(
            controller: controller,
            muted: _muted,
            onTogglePlay: _togglePlay,
            onToggleMute: _toggleMute,
          ),
        ),
      ],
    );
  }
}

class _Chrome extends StatelessWidget {
  const _Chrome({
    required this.controller,
    required this.muted,
    required this.onTogglePlay,
    required this.onToggleMute,
  });

  final VideoPlayerController controller;
  final bool muted;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    final playing = controller.value.isPlaying;
    final position = controller.value.position;
    final duration = controller.value.duration;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: IconButton(
            onPressed: onTogglePlay,
            iconSize: 68,
            icon: Icon(
              playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: AppColors.white.withValues(alpha: 0.92),
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 10,
          child: Row(
            children: [
              IconButton(
                onPressed: onTogglePlay,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                icon: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  color: AppColors.white,
                ),
              ),
              IconButton(
                onPressed: onToggleMute,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                icon: Icon(
                  muted ? Icons.volume_off : Icons.volume_up,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    color: const Color(0xFFE53935),
                    backgroundColor: const Color(0x66FFFFFF),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _format(position),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
