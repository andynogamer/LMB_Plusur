import 'dart:io' show Platform;
import 'dart:ui';

import 'package:ar_flutter_plugin_plus/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipo_model.dart';
import '../models/marcador_model.dart';
import '../routes/app_routes.dart';
import '../services/arcore_install.dart';
import '../services/data_service.dart';
import '../services/feedback_service.dart';
import '../services/image_detection_gate.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/ar_model_viewport.dart';
import '../widgets/feature_card.dart';
import '../widgets/primary_button.dart';

/// AR scan + 3D stage (US-06 / US-07).
///
/// Live recognition is ARCore/ARKit image tracking via `ar_flutter_plugin_plus`.
class ArViewScreen extends StatefulWidget {
  const ArViewScreen({
    super.key,
    this.equipoHint,
  });

  final Equipo? equipoHint;

  @override
  State<ArViewScreen> createState() => _ArViewScreenState();
}

class _ArViewScreenState extends State<ArViewScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final DataService _dataService = DataService();
  final ImageDetectionGate _detectionGate = ImageDetectionGate();

  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  List<Marcador> _marcadores = [];
  List<Equipo> _equipos = [];
  Marcador? _detectedMarcador;
  Equipo? _detectedEquipo;
  bool _demoMode = false;
  bool _arReady = false;
  String? _statusMessage;
  late final AnimationController _scanController;

  bool get _supportsArTracking {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final results = await Future.wait([
        _dataService.cargarMarcadores(),
        _dataService.cargarEquipos(),
      ]);
      if (!mounted) return;
      setState(() {
        _marcadores = results[0] as List<Marcador>;
        _equipos = results[1] as List<Equipo>;
        if (!_supportsArTracking) {
          _statusMessage =
              'Este dispositivo no tiene seguimiento AR. Usa el modo demo.';
        }
      });
    } catch (error, stack) {
      debugPrint('AR bootstrap failed: $error\n$stack');
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'No se pudo iniciar el escáner. Prueba el modo demo.';
      });
    }
  }

  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager _,
    ARLocationManager __,
  ) {
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;
    arSessionManager.onImageDetected = (imageName, transformation) {
      _onImageDetected(imageName);
    };
    arSessionManager.onImageTrackingConfigured = (success) {
      debugPrint('LMB_AR image database configured=$success');
      if (!mounted) return;
      setState(() {
        _arReady = success;
        if (!success) {
          _statusMessage =
              'No se pudieron cargar los marcadores. Prueba el modo demo.';
        }
      });
    };
    _prepareArSession();
  }

  Future<void> _prepareArSession() async {
    if (!mounted || _detectedMarcador != null || _arReady) return;

    if (Platform.isAndroid) {
      final status = await ArCoreInstall.ensure();
      if (!mounted) return;
      switch (status) {
        case ArCoreInstallStatus.installRequested:
          setState(() {
            _statusMessage =
                'Google está activando la cámara AR. Acepta la ventana que aparece.';
          });
          return;
        case ArCoreInstallStatus.declined:
        case ArCoreInstallStatus.unsupported:
          setState(() {
            _statusMessage =
                'Este teléfono no puede abrir la cámara AR. Usa el modo demo o elige un equipo.';
          });
          return;
        case ArCoreInstallStatus.installed:
          break;
      }
    }

    final session = _arSessionManager;
    final objects = _arObjectManager;
    if (session == null || objects == null) return;

    try {
      await session.onInitialize(
        showAnimatedGuide: false,
        showFeaturePoints: false,
        showPlanes: false,
        showWorldOrigin: false,
        handleTaps: false,
        trackingImagePaths:
            AppAssets.trackingImagePathsFor(widget.equipoHint?.id),
        continuousImageTracking: true,
        imageTrackingUpdateIntervalMs: 400,
      );
      objects.onInitialize();
    } on PlatformException catch (error) {
      debugPrint('LMB_AR init failed: ${error.code} ${error.message}');
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'No se pudo abrir la cámara AR. Usa el modo demo o elige un equipo.';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _prepareArSession();
    }
  }

  void _onImageDetected(String imageName) {
    if (!mounted || _detectedMarcador != null) return;

    final equipoId = _detectionGate.observe(
      imageName,
      requiredEquipoId: widget.equipoHint?.id,
    );
    debugPrint('LMB_AR detected="$imageName" -> $equipoId');
    if (equipoId == null) return;

    final resolved = _resolverMarcador(equipoId);
    if (resolved == null) {
      setState(() {
        _statusMessage = 'Logo visto, pero no hay contenido para ese equipo.';
      });
      return;
    }

    FeedbackService.instance.success();
    setState(() {
      _detectedMarcador = resolved.marcador;
      _detectedEquipo = resolved.equipo;
      _demoMode = false;
      _statusMessage = null;
    });
  }

  ({Marcador marcador, Equipo? equipo})? _resolverMarcador(String equipoId) {
    Marcador? marcador;
    for (final item in _marcadores) {
      if (item.equipoId == equipoId) {
        marcador = item;
        break;
      }
    }

    Equipo? equipo;
    for (final item in _equipos) {
      if (item.id == equipoId) {
        equipo = item;
        break;
      }
    }

    final logo = AppAssets.logoForEquipo(equipoId);
    if (marcador == null) {
      if (equipo == null || logo == null) return null;
      marcador = Marcador(
        id: 'marcador_$equipoId',
        equipoId: equipoId,
        tipo: TipoMarcador.pelota,
        titulo: equipo.nombre,
        infoTexto: equipo.historia,
        markerImage: logo,
        modelAsset: 'assets/models/placeholders/estadio.glb',
        animaciones: const ['idle'],
      );
    }

    return (marcador: marcador, equipo: equipo);
  }

  Future<void> _activarDemo() async {
    if (_marcadores.isEmpty) {
      setState(() {
        _statusMessage = 'Aún no hay marcadores cargados.';
      });
      return;
    }

    Marcador marcador = _marcadores.first;
    final hint = widget.equipoHint;
    if (hint != null) {
      for (final m in _marcadores) {
        if (m.equipoId == hint.id) {
          marcador = m;
          break;
        }
      }
    }

    Equipo? equipo;
    if (marcador.equipoId != null) {
      for (final e in _equipos) {
        if (e.id == marcador.equipoId) {
          equipo = e;
          break;
        }
      }
    }
    equipo ??= hint;

    await FeedbackService.instance.tap();
    if (!mounted) return;
    setState(() {
      _detectedMarcador = marcador;
      _detectedEquipo = equipo;
      _demoMode = true;
      _statusMessage = null;
    });
  }

  void _reintentar() {
    _detectionGate.reset();
    setState(() {
      _detectedMarcador = null;
      _detectedEquipo = null;
      _demoMode = false;
      _statusMessage = null;
    });
  }

  void _cerrarExperiencia() {
    Navigator.of(context).maybePop();
  }

  String get _scanHintCopy {
    final hint = widget.equipoHint;
    if (hint != null) {
      return 'Apunta al marcador AR de ${hint.nombre}';
    }
    return 'Apunta al marcador AR del equipo';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanController.dispose();
    _arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detected = _detectedMarcador;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_supportsArTracking)
            Positioned.fill(
              child: ARView(
                onARViewCreated: _onARViewCreated,
                planeDetectionConfig: PlaneDetectionConfig.none,
                permissionPromptDescription:
                    'Necesitamos la cámara para escanear logos de la Zona Sur.',
                permissionPromptButtonText: 'Permitir cámara',
                permissionPromptParentalRestriction:
                    'La cámara está restringida. Revisa los ajustes del dispositivo.',
              ),
            )
          else
            const _ArFallbackBackground(),
          if (detected != null)
            const ColoredBox(color: Color(0x9914183B))
          else
            IgnorePointer(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.08, end: 0.22).animate(
                  CurvedAnimation(
                    parent: _scanController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: const ColoredBox(color: Color(0x3314183B)),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _cerrarExperiencia,
                        tooltip: 'Salir',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.navy.withValues(alpha: 0.55),
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          detected == null ? 'ESCANEO AR' : 'EXPERIENCIA AR',
                          style: GoogleFonts.poppins(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      if (_demoMode)
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navyCard.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: AppColors.button.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            'MODO DEMO',
                            style: GoogleFonts.poppins(
                              color: AppColors.button,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.button.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const AppLogo(size: 46),
                      ),
                    ],
                  ),
                ),
                if (detected != null) ...[
                  const SizedBox(height: 8),
                  Expanded(child: ArModelViewport(marcador: detected)),
                  _ArMarcadorOverlay(
                    marcador: detected,
                    equipo: _detectedEquipo,
                    demoMode: _demoMode,
                    onRetry: _reintentar,
                    onClose: _cerrarExperiencia,
                  ),
                ] else
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _ScanControls(
                        hint: _scanHintCopy,
                        statusMessage: _statusMessage ??
                            (_arReady
                                ? 'Buscando el marcador AR. Llénalo en el recuadro.'
                                : null),
                        onDemo: _activarDemo,
                        onPickTeam: () {
                          Navigator.of(context).pushNamed(AppRoutes.teams);
                        },
                        onShowMarkers: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.markers,
                            arguments: widget.equipoHint,
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArFallbackBackground extends StatelessWidget {
  const _ArFallbackBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1C2048),
            Color(0xFF0B0D1F),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.view_in_ar,
          color: Color(0x66FFFFFF),
          size: 96,
        ),
      ),
    );
  }
}

class _ScanControls extends StatelessWidget {
  const _ScanControls({
    required this.hint,
    required this.onDemo,
    required this.onPickTeam,
    required this.onShowMarkers,
    this.statusMessage,
  });

  final String hint;
  final String? statusMessage;
  final VoidCallback onDemo;
  final VoidCallback onPickTeam;
  final VoidCallback onShowMarkers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.center_focus_strong_rounded,
            color: AppColors.button,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            hint.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusMessage ??
                'Usa el marcador AR del club (marco con patrón), no un logo suelto. Ábrelo en otra pantalla o imprímelo.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Elegir equipo manualmente',
            icon: Icons.sports_baseball_rounded,
            onPressed: onPickTeam,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onShowMarkers,
            child: Text(
              'Ver marcador para escanear',
              style: GoogleFonts.poppins(
                color: AppColors.button,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onDemo,
            child: Text(
              'Usar modo demo (etiquetado)',
              style: GoogleFonts.poppins(
                color: AppColors.button,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArMarcadorOverlay extends StatelessWidget {
  const _ArMarcadorOverlay({
    required this.marcador,
    required this.demoMode,
    required this.onRetry,
    required this.onClose,
    this.equipo,
  });

  final Marcador marcador;
  final Equipo? equipo;
  final bool demoMode;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          color: AppColors.navy.withValues(alpha: 0.92),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.button.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  marcador.titulo.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${marcador.tipo.name.toUpperCase()} · modelo 3D listo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                if (demoMode) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Detección simulada (modo demo)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (equipo != null) ...[
                  FeatureCard(
                    title: 'Historia',
                    subtitle: 'El origen y la identidad del club.',
                    icon: Icons.menu_book_rounded,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.history,
                        arguments: equipo,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  FeatureCard(
                    title: 'Trivia',
                    subtitle: '5 preguntas al azar.',
                    icon: Icons.quiz_rounded,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.trivia,
                        arguments: equipo,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                PrimaryButton(
                  label: 'Escanear otro marcador',
                  icon: Icons.center_focus_strong_rounded,
                  height: 52,
                  onPressed: onRetry,
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: onClose,
                  child: Text(
                    'Salir de la experiencia AR',
                    style: GoogleFonts.poppins(
                      color: AppColors.button,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
