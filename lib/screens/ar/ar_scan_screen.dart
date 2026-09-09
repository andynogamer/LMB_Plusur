import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ar/ar_session_controller.dart';
import '../../ar/ar_session_state.dart';
import '../../ar/ar_tracker.dart';
import '../../ar/marker_registry.dart';
import '../../ar/trackers/arcore_image_tracker.dart';
import '../../ar/trackers/fake_ar_tracker.dart';
import '../../models/equipo_model.dart';
import '../../models/marcador_model.dart';
import '../../services/ar_speech_service.dart';
import '../../services/data_service.dart';
import '../../services/feedback_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import 'widgets/ar_action_bar.dart';
import 'widgets/ar_baseball_vfx.dart';
import 'widgets/ar_demo_badge.dart';
import 'widgets/ar_failed_panel.dart';
import 'widgets/ar_session_body.dart';

/// Scan surface driven only by [ArSessionState]. No detection booleans.
///
/// Production uses [ArCoreImageTracker] when ARCore is installed. Demo mode
/// is [FakeArTracker], entered only with `--dart-define=LMB_AR_DEMO=true`
/// or an injected [tracker]. Tests inject [tracker].
class ArScanScreen extends StatefulWidget {
  const ArScanScreen({
    super.key,
    this.equipoHint,
    this.tracker,
    this.registry,
    this.marcadores,
    this.isDemo = true,
  });

  /// Equipo sugerido al llegar desde el menú del club (D-11).
  final Equipo? equipoHint;

  /// Injected tracker for tests. Production uses [ArCoreImageTracker].
  final ArTracker? tracker;

  final MarkerRegistry? registry;
  final List<Marcador>? marcadores;

  /// Labels the session as demo. Required while the fake tracker is the engine.
  final bool isDemo;

  @override
  State<ArScanScreen> createState() => _ArScanScreenState();
}

class _ArScanScreenState extends State<ArScanScreen>
    with TickerProviderStateMixin {
  ArSessionController? _controller;
  StreamSubscription<ArSessionState>? _states;
  List<Marcador> _marcadores = const [];
  int _cycleIndex = 0;
  ArTracker? _ownedTracker;
  ArCoreImageTracker? _cameraTracker;
  bool _liveIsDemo = false;
  String? _modelNote;
  String? _actionNote;
  bool _gestoPressed = false;
  bool _infoPressed = false;
  bool _efectoPressed = false;
  bool _celebracionVfx = false;
  ArTracker? _liveTracker;
  Timer? _gestoTimer;
  late final AnimationController _spin;
  late final AnimationController _efectoDrive;
  final ValueNotifier<ArSessionState> _uiState =
      ValueNotifier<ArSessionState>(const ArPreparing());

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )
      ..addListener(() {
        _liveTracker?.setPresentationYaw(_spin.value * math.pi * 2);
      })
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        _liveTracker?.setPresentationYaw(0);
        if (_infoPressed) {
          setState(() => _infoPressed = false);
        }
      });
    _efectoDrive = AnimationController(
      vsync: this,
      duration: ArBaseballVfx.duration,
    )
      ..addListener(() {
        _liveTracker?.updateEffect(_efectoDrive.value);
      })
      ..addStatusListener((status) {
        unawaited(_onEfectoDriveStatus(status));
      });
    unawaited(_openSession());
  }

  Future<void> _openSession() async {
    final marcadores =
        widget.marcadores ?? await DataService().cargarMarcadores();
    if (!mounted) return;

    _marcadores = marcadores;
    final registry =
        widget.registry ?? MarkerRegistry.fromMarcadores(marcadores);
    final choice = await _chooseTracker();
    if (!mounted) return;
    await _presentAndBind(choice, registry, marcadores);
  }

  Future<({ArTracker tracker, bool isDemo, bool camera})> _chooseTracker() async {
    if (widget.tracker != null) {
      return (tracker: widget.tracker!, isDemo: widget.isDemo, camera: false);
    }
    // Architecture §9: demo is explicit, never the fallback for a real session.
    const demo = bool.fromEnvironment('LMB_AR_DEMO');
    if (demo) {
      _ownedTracker = FakeArTracker();
      return (tracker: _ownedTracker!, isDemo: true, camera: false);
    }
    final tracker = ArCoreImageTracker();
    _ownedTracker = tracker;
    if (!await tracker.isSupported()) {
      return (tracker: tracker, isDemo: false, camera: false);
    }
    final camera = await tracker.prepareCamera();
    return (tracker: tracker, isDemo: false, camera: camera);
  }

  Future<void> _retry() async {
    final previous = _controller;
    _states?.cancel();
    _controller = null;

    if (mounted) {
      setState(() => _cameraTracker = null);
    }
    await previous?.dispose();
    if (!mounted) return;
    final marcadores = _marcadores;
    final registry =
        widget.registry ?? MarkerRegistry.fromMarcadores(marcadores);
    final choice = await _chooseTracker();
    if (!mounted) return;
    await _presentAndBind(choice, registry, marcadores);
  }

  Future<void> _presentAndBind(
    ({ArTracker tracker, bool isDemo, bool camera}) choice,
    MarkerRegistry registry,
    List<Marcador> marcadores,
  ) async {
    _liveIsDemo = choice.isDemo;
    _liveTracker = choice.tracker;
    _cameraTracker =
        choice.camera && choice.tracker is ArCoreImageTracker
            ? choice.tracker as ArCoreImageTracker
            : null;
    if (mounted) setState(() {});
    await _bind(
      choice.tracker,
      registry,
      marcadores,
      isDemo: choice.isDemo,
    );
  }

  Future<void> _bind(
    ArTracker tracker,
    MarkerRegistry registry,
    List<Marcador> marcadores, {
    required bool isDemo,
  }) async {
    final controller = ArSessionController(
      tracker: tracker,
      registry: registry,
      hintEquipo: widget.equipoHint,
      isDemo: isDemo,
    );
    _controller = controller;
    _states = controller.states.listen((next) {
      _uiState.value = next;
      if (next is ArLocked) {
        unawaited(_attachLockedModel(tracker, next));
      } else {
        unawaited(_releaseActions());
      }
    });

    await controller.start(
      references: [
        for (final marcador in marcadores)
          ArReferenceImage(
            name: marcador.id,
            assetPath: marcador.markerImage,
            physicalWidthMeters: marcador.anchoMetros,
          ),
      ],
    );
    _uiState.value = controller.state;
    if (controller.state is ArLocked) {
      await _attachLockedModel(tracker, controller.state as ArLocked);
    }
  }

  Future<void> _attachLockedModel(ArTracker tracker, ArLocked locked) async {
    await tracker.attachModel(
      trackerName: locked.marcador.id,
      glbAsset: locked.marcador.modelAsset,
    );
    if (!mounted) return;
    final note = tracker is ArCoreImageTracker
        ? modelFallbackCopy(tracker.modelAttach)
        : null;
    if (mounted && (_modelNote != note || _actionNote != null)) {
      setState(() {
        _modelNote = note;
        _actionNote = null;
      });
    }
    if (locked.marcador.animaciones.contains(kClipIdle)) {
      await tracker.playClip(
        trackerName: locked.marcador.id,
        clipName: kClipIdle,
        loop: true,
      );
    }
  }

  Future<void> _releaseActions() async {
    _gestoTimer?.cancel();
    _gestoTimer = null;
    _efectoDrive.stop();
    _efectoDrive.value = 0;
    _efectoLooping = false;
    if (_spin.isAnimating) {
      _spin.stop();
    }
    _liveTracker?.setPresentationYaw(0);
    await _liveTracker?.clearEffect();
    await ArSpeechService.instance.stop();
    if (!mounted) return;
    if (!_gestoPressed &&
        !_infoPressed &&
        !_efectoPressed &&
        !_celebracionVfx &&
        _actionNote == null) {
      return;
    }
    setState(() {
      _gestoPressed = false;
      _infoPressed = false;
      _efectoPressed = false;
      _celebracionVfx = false;
      _actionNote = null;
    });
  }

  void _startEfectoDrive({required bool loop}) {
    _efectoLooping = loop;
    _efectoDrive
      ..stop()
      ..forward(from: 0);
  }

  bool _efectoLooping = false;

  Future<void> _onEfectoDriveStatus(AnimationStatus status) async {
    if (status != AnimationStatus.completed || !mounted) return;
    if (_efectoLooping && _efectoPressed) {
      await _restartEfectoLoop();
      return;
    }
    if (!_efectoLooping) {
      await _finishOneshotEfecto();
    }
  }

  Future<void> _restartEfectoLoop() async {
    final tracker = _liveTracker;
    final state = _uiState.value;
    if (tracker == null || state is! ArLocked || !_efectoPressed) return;
    await tracker.clearEffect();
    final placed = await tracker.attachEffect(
      trackerName: state.marcador.id,
      glbAsset: kEfectoJonronAsset,
    );
    if (!mounted || !placed || !_efectoPressed) return;
    _efectoDrive.forward(from: 0);
  }

  Future<void> _finishOneshotEfecto() async {
    await _liveTracker?.clearEffect();
    if (!mounted) return;
    setState(() {
      _gestoPressed = false;
      _celebracionVfx = false;
    });
  }

  Future<void> _onGesto(Marcador marcador) async {
    final tracker = _liveTracker;
    if (tracker == null) return;
    if (!marcador.animaciones.contains(kClipCelebracion)) {
      await FeedbackService.instance.error();
      if (!mounted) return;
      setState(() => _actionNote = kCelebracionMissingCopy);
      return;
    }
    if (_gestoPressed) {
      _gestoTimer?.cancel();
      _gestoTimer = null;
      _efectoDrive.stop();
      await tracker.clearEffect();
      await tracker.playClip(
        trackerName: marcador.id,
        clipName: kClipIdle,
        loop: true,
      );
      if (!mounted) return;
      setState(() {
        _gestoPressed = false;
        _celebracionVfx = false;
      });
      return;
    }
    final played = await tracker.playClip(
      trackerName: marcador.id,
      clipName: kClipCelebracion,
      loop: false,
    );
    if (!mounted) return;
    if (!played) {
      await FeedbackService.instance.error();
      setState(() => _actionNote = kCelebracionFailedCopy);
      return;
    }
    await FeedbackService.instance.success();
    final placed = await tracker.attachEffect(
      trackerName: marcador.id,
      glbAsset: kEfectoJonronAsset,
    );
    if (!mounted) return;
    setState(() {
      _gestoPressed = true;
      _celebracionVfx = placed;
      _efectoPressed = false;
      _actionNote = null;
    });
    if (placed) {
      _startEfectoDrive(loop: false);
    } else {
      _gestoTimer?.cancel();
      _gestoTimer = Timer(kCelebracionClipLength, () {
        if (!mounted) return;
        setState(() => _gestoPressed = false);
      });
    }
  }

  Future<void> _onEfecto() async {
    final tracker = _liveTracker;
    final state = _uiState.value;
    if (tracker == null || state is! ArLocked) return;
    await FeedbackService.instance.tap();
    if (!mounted) return;
    if (_efectoPressed) {
      _efectoDrive.stop();
      _efectoLooping = false;
      await tracker.clearEffect();
      if (!mounted) return;
      setState(() {
        _efectoPressed = false;
        _celebracionVfx = false;
        _actionNote = null;
      });
      return;
    }
    final placed = await tracker.attachEffect(
      trackerName: state.marcador.id,
      glbAsset: kEfectoJonronAsset,
    );
    if (!mounted) return;
    if (!placed) {
      await FeedbackService.instance.error();
      setState(() => _actionNote = 'No pudimos mostrar el efecto 3D.');
      return;
    }
    setState(() {
      _efectoPressed = true;
      _celebracionVfx = true;
      _gestoPressed = false;
      _actionNote = null;
    });
    _startEfectoDrive(loop: true);
  }

  Future<void> _onInfo(Marcador marcador) async {
    if (_infoPressed) {
      await ArSpeechService.instance.stop();
      _spin.stop();
      _liveTracker?.setPresentationYaw(0);
      if (!mounted) return;
      setState(() => _infoPressed = false);
      return;
    }
    await FeedbackService.instance.success();
    if (!mounted) return;
    setState(() {
      _infoPressed = true;
      _actionNote = null;
    });
    _spin.forward(from: 0);
    await ArSpeechService.instance.speak(
      '${marcador.titulo}. ${marcador.infoTexto}',
    );
  }

  void _simulateNext() {
    final tracker = widget.tracker ?? _ownedTracker;
    final controller = _controller;
    if (tracker is! FakeArTracker || _marcadores.isEmpty || controller == null) {
      return;
    }
    final marcador = _marcadores[_cycleIndex % _marcadores.length];
    _cycleIndex = (_cycleIndex + 1) % _marcadores.length;
    for (var hit = 0; hit < controller.needed; hit++) {
      tracker.emit(
        ArDetection(
          trackerName: marcador.id,
          pose: Matrix4.identity(),
          isFullyTracked: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _gestoTimer?.cancel();
    _efectoDrive.dispose();
    _spin.dispose();
    unawaited(ArSpeechService.instance.stop());
    _states?.cancel();
    _uiState.dispose();
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ArSessionState>(
      valueListenable: _uiState,
      builder: (context, state, _) => _scaffold(context, state),
    );
  }

  Widget _scaffold(BuildContext context, ArSessionState state) {
    final showDemoBadge = _liveIsDemo || state is ArLocked && state.isDemo;
    final failed = state is ArFailed ? state : null;
    final camera = _cameraTracker;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (camera != null) Positioned.fill(child: camera.buildSurface()),
          if (state is ArLocked && (_efectoPressed || _celebracionVfx))
            Positioned.fill(
              child: ArBaseballVfx(
                active: true,
                oneshot: _celebracionVfx && !_efectoPressed,
                onFinished: () {
                  if (!mounted) return;
                  setState(() => _celebracionVfx = false);
                },
              ),
            ),
          DecoratedBox(
            decoration: camera == null
                ? const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1C2048), Color(0xFF0B0D1F)],
                    ),
                  )
                : const BoxDecoration(),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppColors.navy.withValues(alpha: 0.55),
                          ),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.white,
                          ),
                        ),
                        const Spacer(),
                        if (showDemoBadge) ...[
                          const ArDemoBadge(),
                          const SizedBox(width: 10),
                        ],
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
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: DecoratedBox(
                      decoration: camera == null
                          ? const BoxDecoration()
                          : BoxDecoration(
                              color: AppColors.navy.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(16),
                            ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: camera == null ? 0 : 16,
                          vertical: camera == null ? 0 : 16,
                        ),
                        child: failed == null
                            ? ArSessionBody(
                                state: state,
                                equipoHint: widget.equipoHint,
                                onSimulateNext:
                                    _liveIsDemo ? _simulateNext : null,
                                modelNote: state is ArLocked ? _modelNote : null,
                                infoActive: state is ArLocked && _infoPressed,
                                actions: state is ArLocked
                                    ? ArActionBar(
                                        gestoPressed: _gestoPressed,
                                        infoPressed: _infoPressed,
                                        efectoPressed: _efectoPressed,
                                        note: _actionNote,
                                        onGesto: () => unawaited(
                                          _onGesto(state.marcador),
                                        ),
                                        onInfo: () => unawaited(
                                          _onInfo(state.marcador),
                                        ),
                                        onEfecto: () => unawaited(_onEfecto()),
                                      )
                                    : null,
                                onExit: state is ArLocked
                                    ? () => Navigator.of(context).maybePop()
                                    : null,
                              )
                            : ArFailedPanel(
                                failure: failed,
                                onRetry: _retry,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
