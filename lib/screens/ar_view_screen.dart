import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/equipo_model.dart';
import '../models/marcador_model.dart';
import '../routes/app_routes.dart';
import '../services/data_service.dart';
import '../services/feedback_service.dart';
import '../services/logo_matcher_service.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/ar_model_viewport.dart';
import '../widgets/feature_card.dart';
import '../widgets/primary_button.dart';

/// AR scan + 3D stage (US-06 / US-07).
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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final DataService _dataService = DataService();
  final LogoMatcherService _matcher = LogoMatcherService();

  CameraController? _camera;
  List<Marcador> _marcadores = [];
  List<Equipo> _equipos = [];
  Marcador? _detectedMarcador;
  Equipo? _detectedEquipo;
  bool _demoMode = false;
  bool _busy = false;
  bool _permissionDenied = false;
  bool _cameraReady = false;
  String? _statusMessage;
  Timer? _scanTimer;
  late final AnimationController _scanController;

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
      _marcadores = results[0] as List<Marcador>;
      _equipos = results[1] as List<Equipo>;
      await _matcher.loadMarcadores(_marcadores);
      if (!mounted) return;
      await _initCamera();
    } catch (error, stack) {
      debugPrint('AR bootstrap failed: $error\n$stack');
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'No se pudo iniciar el esc?ner. Prueba el modo demo.';
      });
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _permissionDenied = true;
        _statusMessage =
            'Necesitamos la c?mara para escanear logos. Puedes elegir el equipo manualmente.';
      });
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'No hay c?mara disponible. Usa el modo demo o elige un equipo.';
      });
      return;
    }

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
    } catch (error) {
      debugPrint('Camera init failed: $error');
      if (!mounted) return;
      setState(() {
        _statusMessage = 'No se pudo abrir la c?mara. Usa el modo demo.';
      });
      return;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }

    await _camera?.dispose();
    _camera = controller;
    setState(() {
      _cameraReady = true;
      _permissionDenied = false;
      _statusMessage = null;
    });
    _startScanLoop();
  }

  void _startScanLoop() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _captureAndMatch();
    });
  }

  Future<void> _captureAndMatch() async {
    final controller = _camera;
    if (_busy ||
        _detectedMarcador != null ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    _busy = true;
    try {
      final shot = await controller.takePicture();
      final bytes = await File(shot.path).readAsBytes();
      try {
        await File(shot.path).delete();
      } catch (_) {}

      final match = await _matcher.matchFromCamera(
        bytes,
        preferEquipoId: widget.equipoHint?.id,
      );
      debugPrint(
        'LMB_SCAN equipo=${match?.equipoId} dist=${match?.distance} '
        'accepted=${match?.accepted}',
      );
      if (!mounted) return;

      if (match == null || !match.accepted) {
        setState(() {
          _statusMessage = match == null
              ? 'No se ley? el logo. Ac?rcalo al centro de la c?mara.'
              : 'A?n no coincide. Centra el logo (${match.distance}).';
        });
        return;
      }

      final resolved = _resolverMarcador(match.equipoId);
      if (resolved == null) {
        setState(() {
          _statusMessage = 'Logo visto, pero no hay contenido para ese equipo.';
        });
        return;
      }

      _scanTimer?.cancel();
      await FeedbackService.instance.success();
      if (!mounted) return;
      setState(() {
        _detectedMarcador = resolved.marcador;
        _detectedEquipo = resolved.equipo;
        _demoMode = false;
        _statusMessage = null;
      });
    } catch (error) {
      debugPrint('Scan frame failed: $error');
    } finally {
      _busy = false;
    }
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
        _statusMessage = 'A?n no hay marcadores cargados.';
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

    _scanTimer?.cancel();
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
    setState(() {
      _detectedMarcador = null;
      _detectedEquipo = null;
      _demoMode = false;
      _statusMessage = null;
    });
    if (_cameraReady) {
      _startScanLoop();
    }
  }

  void _cerrarExperiencia() {
    Navigator.of(context).maybePop();
  }

  String get _scanHintCopy {
    final hint = widget.equipoHint;
    if (hint != null) {
      return 'Apunta al logo de ${hint.nombre}';
    }
    return 'Apunta al logo de un equipo (marcador AR)';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _camera;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _scanTimer?.cancel();
      controller.dispose();
      _camera = null;
      _cameraReady = false;
    } else if (state == AppLifecycleState.resumed &&
        _detectedMarcador == null &&
        !_permissionDenied) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanTimer?.cancel();
    _scanController.dispose();
    _camera?.dispose();
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
          if (_cameraReady && _camera != null)
            CameraPreview(_camera!)
          else
            const _ArFallbackBackground(),
          if (detected != null)
            const ColoredBox(color: Color(0x9914183B))
          else
            IgnorePointer(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.12, end: 0.4).animate(
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
                        statusMessage: _statusMessage,
                        permissionDenied: _permissionDenied,
                        onDemo: _activarDemo,
                        onRetryPermission: _initCamera,
                        onPickTeam: () {
                          Navigator.of(context).pushNamed(AppRoutes.teams);
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
    required this.onRetryPermission,
    this.statusMessage,
    this.permissionDenied = false,
  });

  final String hint;
  final String? statusMessage;
  final bool permissionDenied;
  final VoidCallback onDemo;
  final VoidCallback onPickTeam;
  final VoidCallback onRetryPermission;

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
                'Escaneando logos de la Zona Sur? Mant?n el marcador centrado.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          if (permissionDenied)
            PrimaryButton(
              label: 'Permitir c?mara',
              icon: Icons.camera_alt_rounded,
              onPressed: onRetryPermission,
            ),
          if (permissionDenied) const SizedBox(height: 10),
          PrimaryButton(
            label: 'Elegir equipo manualmente',
            icon: Icons.sports_baseball_rounded,
            onPressed: onPickTeam,
          ),
          const SizedBox(height: 10),
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
                  '${marcador.tipo.name.toUpperCase()} ? modelo 3D listo',
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
                    'Detecci?n simulada (modo demo)',
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
