import '../models/marcador_model.dart';

/// The ONLY place a tracker name becomes app content.
///
/// Lookup is an exact map hit (D-14). An unknown name returns null — the
/// session stays searching. There is no nearest match and no fuzzy fallback.
class MarkerRegistry {
  const MarkerRegistry(this._byTrackerName);

  final Map<String, Marcador> _byTrackerName;

  /// Keys the registry by [Marcador.id], which MUST equal the reference-image
  /// filename stem the tracker reports.
  factory MarkerRegistry.fromMarcadores(List<Marcador> marcadores) {
    return MarkerRegistry({
      for (final marcador in marcadores) marcador.id: marcador,
    });
  }

  /// Exact lookup. Returns null for anything not registered.
  Marcador? resolve(String trackerName) => _byTrackerName[trackerName];
}
