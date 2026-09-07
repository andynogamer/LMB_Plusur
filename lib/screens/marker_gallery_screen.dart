import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipo_model.dart';
import '../services/data_service.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/screen_background.dart';

/// Full-screen AR tracking cards so the camera can see a unique target.
class MarkerGalleryScreen extends StatefulWidget {
  const MarkerGalleryScreen({
    super.key,
    this.equipo,
  });

  final Equipo? equipo;

  @override
  State<MarkerGalleryScreen> createState() => _MarkerGalleryScreenState();
}

class _MarkerGalleryScreenState extends State<MarkerGalleryScreen> {
  List<Equipo> _equipos = [];

  @override
  void initState() {
    super.initState();
    DataService().cargarEquipos().then((value) {
      if (!mounted) return;
      setState(() => _equipos = value);
    });
  }

  Equipo? _equipoById(String id) {
    if (widget.equipo?.id == id) return widget.equipo;
    for (final item in _equipos) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.equipo;
    if (focused != null) {
      final asset = AppAssets.trackingMarkerById[focused.id];
      return Scaffold(
        body: ScreenBackground(
          child: Column(
            children: [
              AppHeader(
                title: 'Marcador AR',
                subtitle: focused.nombre,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  children: [
                    Text(
                      'Muestra esta imagen a la cámara (otra pantalla o impresa). No uses un logo genérico del equipo: ARCore los confunde.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (asset != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ColoredBox(
                          color: AppColors.white,
                          child: Image.asset(asset, fit: BoxFit.contain),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: ScreenBackground(
        child: Column(
          children: [
            const AppHeader(
              title: 'Marcadores AR',
              subtitle: 'Uno por club de la Zona Sur',
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: AppAssets.trackingMarkerById.length,
                itemBuilder: (context, index) {
                  final entry =
                      AppAssets.trackingMarkerById.entries.elementAt(index);
                  final match = _equipoById(entry.key);
                  return Material(
                    color: AppColors.navyCard,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MarkerGalleryScreen(
                              equipo: match ??
                                  Equipo(
                                    id: entry.key,
                                    nombre: entry.key,
                                    historia: '',
                                    fundacion: 0,
                                    trivias: const [],
                                  ),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: ColoredBox(
                                  color: AppColors.white,
                                  child: Image.asset(
                                    entry.value,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              match?.nombre ?? entry.key,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
