import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipo_model.dart';
import '../models/video_archivo.dart';
import '../services/data_service.dart';
import '../services/filter_engine.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/filtros_partido.dart';
import '../widgets/highlight_video_player.dart';
import '../widgets/screen_background.dart';

/// Video archive. [equipo] filters to that club; null opens the full catalog.
class HighlightsScreen extends StatefulWidget {
  const HighlightsScreen({
    super.key,
    this.equipo,
  });

  final Equipo? equipo;

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  final DataService _data = DataService();
  List<VideoArchivo> _videos = const [];
  Map<String, String> _nombres = const {};
  String? _playingId;
  FiltroPartido _filtro = FiltroPartido.ninguno;
  bool _cargando = true;
  bool _falloCarga = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _falloCarga = false;
    });
    try {
      final videos = await _data.cargarVideos();
      final equipos = await _data.cargarEquipos();
      if (!mounted) return;
      setState(() {
        _videos = _paraEsteClub(videos);
        _nombres = {for (final equipo in equipos) equipo.id: equipo.nombre};
        _cargando = false;
        _falloCarga = videos.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _falloCarga = true;
      });
    }
  }

  List<VideoArchivo> _paraEsteClub(List<VideoArchivo> videos) {
    final equipo = widget.equipo;
    if (equipo == null) return videos;
    return videos.where((video) => video.equipoId == equipo.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    final equipo = widget.equipo;
    return Scaffold(
      body: ScreenBackground(
        child: Column(
          children: [
            AppHeader(
              title: equipo?.displayName ?? 'ARCHIVO DE VIDEOS',
              subtitle: equipo == null
                  ? 'Videos de la Zona Sur'
                  : 'Videos del club',
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.button,
          strokeWidth: 2.4,
        ),
      );
    }
    if (_falloCarga) {
      return _mensaje(
        'No se pudo abrir el archivo de videos.',
        onRetry: _cargar,
      );
    }
    if (_videos.isEmpty) {
      return _mensaje('Este club aún no tiene videos en el archivo.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: _videos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 22),
      itemBuilder: (context, index) {
        final video = _videos[index];
        final club = video.equipoId == null ? null : _nombres[video.equipoId];
        final playing = _playingId == video.id;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              video.titulo.toUpperCase(),
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.4,
              ),
            ),
            if (club != null) ...[
              const SizedBox(height: 4),
              Text(
                club,
                style: GoogleFonts.poppins(
                  color: AppColors.button,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              video.descripcion,
              style: GoogleFonts.poppins(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            if (playing) ...[
              HighlightVideoPlayer(
                url: video.url,
                isActive: true,
                filtro: _filtro,
                onPlay: () => setState(() => _playingId = video.id),
              ),
              const SizedBox(height: 12),
              FiltrosPartido(
                seleccionado: _filtro,
                onChanged: (filtro) => setState(() => _filtro = filtro),
              ),
            ] else
              _poster(video),
          ],
        );
      },
    );
  }

  Widget _poster(VideoArchivo video) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.black,
        child: InkWell(
          onTap: () => setState(() => _playingId = video.id),
          child: const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(
              child: Icon(
                Icons.play_circle_fill,
                color: AppColors.white,
                size: 68,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mensaje(String texto, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              texto,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'Reintentar',
                  style: GoogleFonts.poppins(
                    color: AppColors.button,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
