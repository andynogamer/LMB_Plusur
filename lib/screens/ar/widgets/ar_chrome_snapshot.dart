/// Pressed-state and overlay notes for AR chrome.
///
/// Held in a [ValueNotifier] so action taps do not [State.setState] the
/// scaffold that owns the camera platform view.
class ArChromeSnapshot {
  const ArChromeSnapshot({
    this.gestoPressed = false,
    this.infoPressed = false,
    this.efectoPressed = false,
    this.celebracionVfx = false,
    this.actionNote,
    this.modelNote,
  });

  static const empty = ArChromeSnapshot();

  final bool gestoPressed;
  final bool infoPressed;
  final bool efectoPressed;
  final bool celebracionVfx;
  final String? actionNote;
  final String? modelNote;

  ArChromeSnapshot copyWith({
    bool? gestoPressed,
    bool? infoPressed,
    bool? efectoPressed,
    bool? celebracionVfx,
    Object? actionNote = _keep,
    Object? modelNote = _keep,
  }) {
    return ArChromeSnapshot(
      gestoPressed: gestoPressed ?? this.gestoPressed,
      infoPressed: infoPressed ?? this.infoPressed,
      efectoPressed: efectoPressed ?? this.efectoPressed,
      celebracionVfx: celebracionVfx ?? this.celebracionVfx,
      actionNote:
          identical(actionNote, _keep) ? this.actionNote : actionNote as String?,
      modelNote:
          identical(modelNote, _keep) ? this.modelNote : modelNote as String?,
    );
  }
}

const Object _keep = Object();
