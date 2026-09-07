import '../models/equipo_model.dart';
import '../models/marcador_model.dart';
import 'ar_tracker.dart';

sealed class ArSessionState {
  const ArSessionState();
}

/// Checking permissions and ARCore availability.
class ArPreparing extends ArSessionState {
  const ArPreparing();
}

/// Camera live, database loaded, nothing recognised yet.
class ArSearching extends ArSessionState {
  const ArSearching({this.hintEquipo});

  /// D-11 "Abrir experiencia AR" hint. Not an identity guess.
  final Equipo? hintEquipo;
}

/// Seen but not yet confirmed by the debounce gate. UI may show progress.
class ArCandidate extends ArSessionState {
  const ArCandidate({
    required this.marcador,
    required this.hits,
    required this.needed,
  });

  final Marcador marcador;
  final int hits;
  final int needed;
}

/// Confirmed. This is the only state that may render 3D or AR actions.
class ArLocked extends ArSessionState {
  const ArLocked({required this.marcador, required this.isDemo});

  final Marcador marcador;

  /// Drives the mandatory "MODO DEMO" badge.
  final bool isDemo;
}

/// Was locked, target left the frame. Keep content, show a re-aim hint.
class ArLost extends ArSessionState {
  const ArLost({required this.marcador});

  final Marcador marcador;
}

/// Spanish copy for one [ArTrackerFailure]. Bound by architecture §8.
class ArFailureCopy {
  const ArFailureCopy({
    required this.titulo,
    required this.cuerpo,
    required this.acciones,
  });

  final String titulo;
  final String cuerpo;
  final List<String> acciones;
}

/// Terminal for this attempt. Always carries recovery affordances.
class ArFailed extends ArSessionState {
  const ArFailed({required this.failure});

  final ArTrackerFailure failure;

  ArFailureCopy get copy => arFailureCopy(failure);
}

/// Title, body and recovery actions for every tracker failure (architecture §8).
ArFailureCopy arFailureCopy(ArTrackerFailure failure) {
  return switch (failure) {
    ArTrackerFailure.permissionDenied => const ArFailureCopy(
        titulo: 'Cámara sin permiso',
        cuerpo: 'Necesitamos la cámara para escanear los marcadores.',
        acciones: ['Abrir ajustes', 'Elegir equipo'],
      ),
    ArTrackerFailure.arCoreUnavailable => const ArFailureCopy(
        titulo: 'Este dispositivo no soporta AR',
        cuerpo: 'Puedes explorar los equipos y videos sin escanear.',
        acciones: ['Elegir equipo'],
      ),
    ArTrackerFailure.arCoreNeedsInstall => const ArFailureCopy(
        titulo: 'Falta Servicios de Play para AR',
        cuerpo: 'Instálalo para usar la experiencia AR.',
        acciones: ['Instalar', 'Elegir equipo'],
      ),
    ArTrackerFailure.databaseBuildFailed => const ArFailureCopy(
        titulo: 'No pudimos preparar los marcadores',
        cuerpo: 'Vuelve a intentarlo.',
        acciones: ['Reintentar', 'Elegir equipo'],
      ),
    ArTrackerFailure.sessionLost => const ArFailureCopy(
        titulo: 'Perdimos el seguimiento',
        cuerpo: 'Apunta de nuevo al marcador.',
        acciones: ['Reintentar'],
      ),
    ArTrackerFailure.unknown => const ArFailureCopy(
        titulo: 'Algo salió mal en AR',
        cuerpo: 'Puedes reintentar o elegir tu equipo.',
        acciones: ['Reintentar', 'Elegir equipo'],
      ),
  };
}
