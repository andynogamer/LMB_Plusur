import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/baseball_history_entry.dart';
import '../services/data_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/image_placeholder.dart';
import '../widgets/screen_background.dart';

class BaseballHistoryScreen extends StatefulWidget {
  const BaseballHistoryScreen({super.key});

  @override
  State<BaseballHistoryScreen> createState() => _BaseballHistoryScreenState();
}

class _BaseballHistoryScreenState extends State<BaseballHistoryScreen> {
  Future<List<BaseballHistoryEntry>> _history = DataService()
      .cargarHistoriaBeisbol();

  void _retry() {
    setState(() => _history = DataService().cargarHistoriaBeisbol());
  }

  Future<void> _openSource(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrir el enlace de la fuente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: Column(
          children: [
            const AppHeader(
              title: 'Historia del béisbol',
              subtitle: 'Un juego con historia en todo el mundo',
            ),
            Expanded(
              child: FutureBuilder<List<BaseballHistoryEntry>>(
                future: _history,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.button),
                    );
                  }
                  if (snapshot.hasError) {
                    return _HistoryLoadError(onRetry: _retry);
                  }
                  final entries = snapshot.data ?? const [];
                  if (entries.isEmpty) {
                    return const _HistoryLoadError();
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _Introduction(entryCount: entries.length),
                      const SizedBox(height: 18),
                      for (final entry in entries) ...[
                        _HistoryCard(entry: entry, onOpenSource: _openSource),
                        const SizedBox(height: 16),
                      ],
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

class _Introduction extends StatelessWidget {
  const _Introduction({required this.entryCount});

  final int entryCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navyCard.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.button.withValues(alpha: 0.2)),
      ),
      child: Text(
        'Recorre $entryCount momentos que ayudaron a formar el béisbol moderno: '
        'la profesionalización, las Ligas Negras, la integración y el juego '
        'internacional. La historia del deporte también es la historia de sus '
        'comunidades, cambios y desafíos.',
        style: GoogleFonts.poppins(
          color: AppColors.white,
          fontSize: 14,
          height: 1.55,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.onOpenSource});

  final BaseballHistoryEntry entry;
  final ValueChanged<String> onOpenSource;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyCard.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.button.withValues(alpha: 0.16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _HistoryImage(url: entry.imagenUrl),
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    entry.periodo,
                    style: GoogleFonts.poppins(
                      color: AppColors.button,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.titulo,
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.resumen,
                  style: GoogleFonts.poppins(
                    color: AppColors.button,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  entry.detalle,
                  style: GoogleFonts.poppins(
                    color: AppColors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Crédito: ${entry.imagenCredito}',
                  style: GoogleFonts.poppins(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                Text(
                  'Licencia: ${entry.licenciaImagen}',
                  style: GoogleFonts.poppins(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 0,
                  children: [
                    _SourceLink(
                      label: 'Fuente histórica',
                      onPressed: () => onOpenSource(entry.fuenteHistoricaUrl),
                    ),
                    _SourceLink(
                      label: 'Imagen y licencia',
                      onPressed: () => onOpenSource(entry.imagenFuenteUrl),
                    ),
                    if (entry.licenciaImagenUrl != entry.imagenFuenteUrl)
                      _SourceLink(
                        label: 'Texto de licencia',
                        onPressed: () => onOpenSource(entry.licenciaImagenUrl),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryImage extends StatelessWidget {
  const _HistoryImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const fallback = ImagePlaceholder(height: 210);
    return CachedNetworkImage(
      imageUrl: url,
      height: 210,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.button,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
      icon: const Icon(Icons.open_in_new_rounded, size: 14),
      label: Text(label),
    );
  }
}

class _HistoryLoadError extends StatelessWidget {
  const _HistoryLoadError({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_baseball_rounded,
              color: AppColors.button,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              'No pudimos cargar la historia del béisbol.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Intentar de nuevo'),
              ),
          ],
        ),
      ),
    );
  }
}
