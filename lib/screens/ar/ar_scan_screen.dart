import 'dart:async';

import 'package:flutter/material.dart';

import '../../ar/ar_session_controller.dart';
import '../../ar/ar_session_state.dart';
import '../../ar/ar_tracker.dart';
import '../../ar/marker_registry.dart';
import '../../ar/trackers/fake_ar_tracker.dart';
import '../../models/equipo_model.dart';
import '../../models/marcador_model.dart';
import '../../services/data_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import 'widgets/ar_demo_badge.dart';
import 'widgets/ar_failed_panel.dart';
import 'widgets/ar_session_body.dart';

/// Scan surface driven only by [ArSessionState]. No detection booleans.
///
/// This slice always uses [FakeArTracker] unless a test injects another
/// tracker. A real camera session arrives in a later item.
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

  /// Injected tracker for tests. Production uses [FakeArTracker].
  final ArTracker? tracker;

  final MarkerRegistry? registry;
  final List<Marcador>? marcadores;

  /// Labels the session as demo. Required while the fake tracker is the engine.
  final bool isDemo;

  @override
  State<ArScanScreen> createState() => _ArScanScreenState();
}

class _ArScanScreenState extends State<ArScanScreen> {
  ArSessionController? _controller;
  StreamSubscription<ArSessionState>? _states;
  List<Marcador> _marcadores = const [];
  int _cycleIndex = 0;
  FakeArTracker? _ownedTracker;
  final ValueNotifier<ArSessionState> _uiState =
      ValueNotifier<ArSessionState>(const ArPreparing());

  @override
  void initState() {
    super.initState();
    unawaited(_openSession());
  }

  Future<void> _openSession() async {
    final marcadores =
        widget.marcadores ?? await DataService().cargarMarcadores();
    if (!mounted) return;

    _marcadores = marcadores;
    final registry =
        widget.registry ?? MarkerRegistry.fromMarcadores(marcadores);
    final tracker = widget.tracker ?? (_ownedTracker = FakeArTracker());
    await _bind(tracker, registry, marcadores);
  }

  Future<void> _retry() async {
    final previous = _controller;
    _states?.cancel();
    _controller = null;

    if (widget.tracker == null) {
      _ownedTracker = FakeArTracker();
    }
    final tracker = widget.tracker ?? _ownedTracker!;
    final marcadores = _marcadores;
    final registry =
        widget.registry ?? MarkerRegistry.fromMarcadores(marcadores);
    await previous?.dispose();
    if (!mounted) return;
    await _bind(tracker, registry, marcadores);
  }

  Future<void> _bind(
    ArTracker tracker,
    MarkerRegistry registry,
    List<Marcador> marcadores,
  ) async {
    final controller = ArSessionController(
      tracker: tracker,
      registry: registry,
      hintEquipo: widget.equipoHint,
      isDemo: widget.isDemo,
    );
    _controller = controller;
    _states = controller.states.listen((next) {
      _uiState.value = next;
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
    final showDemoBadge = widget.isDemo || state is ArLocked && state.isDemo;
    final failed = state is ArFailed ? state : null;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1C2048), Color(0xFF0B0D1F)],
          ),
        ),
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
                        backgroundColor: AppColors.navy.withValues(alpha: 0.55),
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
                child: failed == null
                    ? ArSessionBody(
                        state: state,
                        equipoHint: widget.equipoHint,
                        onSimulateNext: widget.isDemo ? _simulateNext : null,
                      )
                    : ArFailedPanel(
                        failure: failed,
                        onRetry: _retry,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
