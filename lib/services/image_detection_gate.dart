import 'marker_id_mapper.dart';

/// Ignores one-frame ARCore mix-ups. The same mapped team id must be seen
/// [requiredHits] times in a row before the scan locks.
class ImageDetectionGate {
  ImageDetectionGate({
    this.requiredHits = 2,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final int requiredHits;
  final DateTime Function() _now;

  String? _pendingId;
  int _hits = 0;
  DateTime? _firstHit;

  static const Duration _staleAfter = Duration(seconds: 2);

  String? observe(String imageName, {String? requiredEquipoId}) {
    final equipoId = MarkerIdMapper.equipoIdFromImageName(imageName);
    if (equipoId == null) return null;
    if (requiredEquipoId != null && equipoId != requiredEquipoId) {
      return null;
    }

    final now = _now();
    if (_pendingId != equipoId ||
        _firstHit == null ||
        now.difference(_firstHit!) > _staleAfter) {
      _pendingId = equipoId;
      _hits = 1;
      _firstHit = now;
      return requiredHits <= 1 ? equipoId : null;
    }

    _hits += 1;
    if (_hits >= requiredHits) return equipoId;
    return null;
  }

  void reset() {
    _pendingId = null;
    _hits = 0;
    _firstHit = null;
  }
}
