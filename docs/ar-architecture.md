# AR architecture contract

**Status:** binding. Referenced by Constitution **Article VI**.
**Version:** 1.0.1 · 2026-09-07
**Scope:** everything under `lib/ar/`, plus AR-related native config.
**Read first:** [`ar-postmortem.md`](./ar-postmortem.md) — this document is its remedy.

---

## 1. The one rule

> **Flutter decides *what* to show. The platform tracker decides *what is
> there*. Neither is allowed to do the other's job.**

Attempt #1 failed because Dart tried to answer "what is the camera looking at?"
That question belongs to ARCore/ARKit. Dart's job starts once an **identity
string** arrives.

---

## 2. Layers and dependency direction

Dependencies point **downward only**. No layer may import from a layer above it.

```
┌──────────────────────────────────────────────────────────┐
│ lib/screens/ar/          UI — widgets, overlays, chrome  │
│                          Knows: ArSessionState, Marcador │
│                          Knows nothing about any plugin  │
├──────────────────────────────────────────────────────────┤
│ lib/ar/ar_session_controller.dart                        │
│                          The state machine (§4).         │
│                          Owns debounce + error mapping.  │
├──────────────────────────────────────────────────────────┤
│ lib/ar/ar_tracker.dart   ABSTRACT SEAM (§3)              │
│   ├─ ArCoreImageTracker  production impl (plugin)        │
│   └─ FakeArTracker       tests + labelled demo mode      │
├──────────────────────────────────────────────────────────┤
│ lib/ar/marker_registry.dart   trackerName → Marcador     │
│ lib/models/marcador_model.dart                           │
│ lib/services/data_service.dart   assets/ar_markers.json  │
└──────────────────────────────────────────────────────────┘
```

**Hard constraint:** the string `ar_flutter_plugin` must appear in exactly one
directory — `lib/ar/trackers/`. If it appears in a screen, the layering is
broken. Grep is the review check:

```bash
rg -l "ar_flutter_plugin" lib/ | rg -v "^lib/ar/trackers/"   # must print nothing
```

---

## 3. The seam: `ArTracker`

Every AR capability enters the app through this interface. It exists so that a
plugin swap, or an ARCore-unavailable device, is a **one-file change** instead of
a rewrite.

```dart
/// A reference image registered in the tracking database.
///
/// [name] is the filename stem and MUST equal the Marcador.id (§5).
/// [physicalWidthMeters] is the printed width — supplying it measurably
/// improves ARCore detection and pose accuracy, so it is required, not
/// optional.
class ArReferenceImage {
  const ArReferenceImage({
    required this.name,
    required this.assetPath,
    required this.physicalWidthMeters,
  });

  final String name;
  final String assetPath;
  final double physicalWidthMeters;
}

/// A detection reported by the platform tracker.
///
/// [trackerName] is the reference-image name registered in the tracking
/// database. It is deterministic and exact — never a similarity guess.
class ArDetection {
  const ArDetection({
    required this.trackerName,
    required this.pose,
    required this.isFullyTracked,
  });

  final String trackerName;
  final Matrix4 pose;

  /// False while ARCore has recognised the image but not yet localised it.
  /// Do not place 3D content until this is true (ARCore guidance).
  final bool isFullyTracked;
}

enum ArTrackerFailure {
  permissionDenied,
  arCoreUnavailable,
  arCoreNeedsInstall,
  databaseBuildFailed,
  sessionLost,
  unknown,
}

class ArTrackerException implements Exception {
  const ArTrackerException(this.failure, [this.cause]);
  final ArTrackerFailure failure;
  final Object? cause;
}

abstract interface class ArTracker {
  /// Whether this device can run the tracker at all. Cheap; no session start.
  Future<bool> isSupported();

  /// Loads the reference-image database and starts the camera session.
  /// Throws [ArTrackerException] — never returns a half-started session.
  Future<void> start({required List<ArReferenceImage> references});

  /// Deterministic detections. Emits per tracked frame; may repeat.
  Stream<ArDetection> get detections;

  /// Attaches a GLB to a detected marker's pose. No-op for fakes.
  Future<void> attachModel({required String trackerName, required String glbAsset});

  /// Plays a named glTF clip on the attached node. Missing clip or a missing
  /// Filament patch returns false and must not fail the session.
  /// Clip names are `idle` (loop), `gesto`, and `celebracion` (one-shot).
  /// Plugin 1.1.3 does
  /// not tick Animator until `tools/patch_filament_clips.ps1`.
  Future<bool> playClip({required String trackerName, required String clipName, bool loop = false});

  /// Extra yaw composed onto the tracked pose. The información action uses
  /// one 360° turn. Zero means the pose alone.
  void setPresentationYaw(double radians);

  Future<void> stop();
  Future<void> dispose();
}
```

### Rules

- `ArTracker` **must not** import `package:flutter/material.dart`. If it needs a
  widget, the concrete impl exposes it separately as `Widget buildSurface()`.
- Implementations **must not** show dialogs, snackbars or navigate. They throw or
  emit; the controller decides UX.
- `detections` is allowed to be chatty. Debouncing lives in the controller (§4),
  never in the tracker.

---

## 4. The session state machine

Attempt #1 tracked AR state in three loose fields on a `StatefulWidget`
(`_detectedTeam`, `_demoMode`, `_detectionTimer`). Every unrepresentable
combination of those was a bug. Replace with one sealed state.

```dart
sealed class ArSessionState {
  const ArSessionState();
}

/// Checking permissions and ARCore availability.
class ArPreparing extends ArSessionState { const ArPreparing(); }

/// Camera live, database loaded, nothing recognised yet.
class ArSearching extends ArSessionState {
  const ArSearching({this.hintEquipo});
  final Equipo? hintEquipo;      // D-11 "Abrir experiencia AR" hint
}

/// Seen but not yet confirmed by the debounce gate. UI may show progress.
class ArCandidate extends ArSessionState {
  const ArCandidate({required this.marcador, required this.hits, required this.needed});
  final Marcador marcador;
  final int hits;
  final int needed;
}

/// Confirmed. This is the only state that may render 3D or AR actions.
class ArLocked extends ArSessionState {
  const ArLocked({required this.marcador, required this.isDemo});
  final Marcador marcador;
  final bool isDemo;             // drives the mandatory "MODO DEMO" badge
}

/// Was locked, target left the frame. Keep content, show a re-aim hint.
class ArLost extends ArSessionState {
  const ArLost({required this.marcador});
  final Marcador marcador;
}

/// Terminal for this attempt. Always carries recovery affordances.
class ArFailed extends ArSessionState {
  const ArFailed({required this.failure});
  final ArTrackerFailure failure;
}
```

### Legal transitions

```
                 ┌──────────────┐
                 │ ArPreparing  │
                 └──────┬───────┘
                        │ supported + permission granted
                        ▼
                 ┌──────────────┐   unknown image / timeout
                 │ ArSearching  │◄───────────────────────┐
                 └──────┬───────┘                        │
        detection       │                                │
                        ▼                                │
                 ┌──────────────┐  different marker seen  │
                 │ ArCandidate  │────────────────────────►┘
                 └──────┬───────┘
          hits >= needed│
                        ▼
                 ┌──────────────┐ target out of frame  ┌──────────┐
                 │  ArLocked    │─────────────────────►│  ArLost  │
                 └──────────────┘◄─────────────────────└──────────┘
                                    re-detected

  Any state ──(ArTrackerException)──► ArFailed
```

**Nothing else is legal.** In particular: `ArPreparing → ArLocked` is forbidden.
That transition is exactly the old "always Guerreros" bug (`BUG-01`) — content
appearing without a real detection.

### Debounce

Reuse the proven pattern from attempt #1's `ImageDetectionGate`: the same
`trackerName` must arrive **`needed` consecutive times within a 2 s window**
before `ArCandidate → ArLocked`. Default `needed = 2`. The clock is injectable so
this is unit-testable without a device.

---

## 5. Identity resolution — `MarkerRegistry`

```dart
/// The ONLY place a tracker name becomes app content.
class MarkerRegistry {
  const MarkerRegistry(this._byTrackerName);
  final Map<String, Marcador> _byTrackerName;

  /// Exact lookup. Returns null for anything not registered.
  Marcador? resolve(String trackerName) => _byTrackerName[trackerName];
}
```

Requirements:

- Lookup is an **exact map hit**. No fuzzy matching, no nearest-neighbour, no
  scores, no thresholds, no `preferEquipoId` tie-breaking.
- An unregistered name resolves to `null` → stay in `ArSearching`. Never guess.
- `trackerName` **is** the reference image's filename stem, and it **must** equal
  the `Marcador.id`. One name, one meaning, verified by a unit test that walks
  `assets/ar_markers.json` and asserts every `markerImage` stem matches its `id`.

Naming convention (also enforced by that test):

```
assets/markers/marcador_<tipo>_<equipo>.png   →  id: marcador_<tipo>_<equipo>
```

---

## 6. Rendering rules

| Surface | Renderer | Allowed |
|---|---|---|
| Live AR session over camera | tracker's scene graph (`ARNode` + GLB) | ✅ the only option |
| "Galería 3D" screen, no camera | `model_viewer_plus` (WebView) | ✅ explicitly non-AR screen |
| Live AR session | `model_viewer_plus` | ❌ **banned** — RC-3 |

A WebView cannot composite into a camera scene graph. Attempt #1 shipped a
WebView card and called it AR; that is not acceptable for the grading gate.

Overlay chrome (buttons, panels, badges) is ordinary Flutter widgets stacked over
the AR surface, using `AppColors` + Poppins + `FeatureCard` / `PrimaryButton`
per Article IX.

---

## 7. Verification strategy

Split by what each method can actually prove. RC-7 happened because these were
conflated.

### Unit / widget tests — the state machine, with `FakeArTracker`

Required coverage before any AR slice merges:

- `ArSearching → ArCandidate → ArLocked` on repeated identical detections.
- Unknown `trackerName` never leaves `ArSearching`.
- Two different markers alternating never reach `ArLocked`.
- Each `ArTrackerFailure` maps to `ArFailed` with the correct Spanish copy (§8).
- `dispose()` cancels subscriptions and stops the tracker (no leaked streams).
- Registry: every `markerImage` stem in `ar_markers.json` equals its `id`.

**Forbidden as a quality claim:** loading a bundled asset and asserting the
matcher returns that asset's id. That is an asset compared with itself.

### `arcoreimg` gate — target quality, at authoring time

Every file in `assets/markers/` must score **≥ 75**, after normalization per
**D-21**. Scores are recorded in `docs/ar-marker-guide.md` §7:

```powershell
powershell -ExecutionPolicy Bypass -File tools/normalize_markers.ps1
$env:ARCOREIMG = "$PWD\tools\bin\arcoreimg.exe"
powershell -ExecutionPolicy Bypass -File tools/score_markers.ps1 -MarkersDir build/markers-normalized
```

This gate is what attempt #1 skipped. Running it revealed that four club logos
already score ≥ 75, making the whole custom-matcher effort unnecessary.

### Device acceptance run — recognition quality

The only evidence that counts for "detection works". Every AR work item that
touches detection must paste this table, filled in, into its PR:

| Marker | Detected correctly | Time to lock | False positives in 30 s | Notes |
|---|---|---|---|---|
| `marcador_estadio_leones` | | | | score 100 |
| `marcador_jugador_olmecas` | | | | score 100 |
| `marcador_trofeo_piratas` | | | | score 100 |
| blank wall (control) | must be **none** | — | | |
| wrong-club logo (control) | must be **none** | — | | use the old unused Pericos `logo_base` (0 keypoints), not the shipped wordmark. Every Zona Sur club now has a scan target. |

Run on a physical Android device with Google Play Services for AR, printed
markers at the size specified in the marker guide, ordinary indoor lighting.

---

## 8. Error taxonomy → user-facing Spanish copy

Failures are **never** silent and **never** a red screen. Every `ArFailed` state
offers a way out — at minimum "Elegir equipo manualmente" (Article III's manual
path).

| `ArTrackerFailure` | Título | Cuerpo | Acciones |
|---|---|---|---|
| `permissionDenied` | Cámara sin permiso | Necesitamos la cámara para escanear los marcadores. | Abrir ajustes · Elegir equipo |
| `arCoreUnavailable` | Este dispositivo no soporta AR | Puedes explorar los equipos y videos sin escanear. | Elegir equipo |
| `arCoreNeedsInstall` | Falta Servicios de Play para AR | Instálalo para usar la experiencia AR. | Instalar · Elegir equipo |
| `databaseBuildFailed` | No pudimos preparar los marcadores | Vuelve a intentarlo. | Reintentar · Elegir equipo |
| `sessionLost` | Perdimos el seguimiento | Apunta de nuevo al marcador. | Reintentar |
| `unknown` | Algo salió mal en AR | Puedes reintentar o elegir tu equipo. | Reintentar · Elegir equipo |

"Marker not recognised" is **not** an error. It is `ArSearching` with a hint —
per Article III's failure modes.

---

## 9. Demo mode

Demo mode is `FakeArTracker` wired to `ArSessionController`, nothing more. It is
**never** the fallback for a failed real session (that is `ArFailed`); it is an
explicit developer/device-limitation path.

- Entered only via an explicit user action or `--dart-define=LMB_AR_DEMO=true`.
- `ArLocked.isDemo == true` ⇒ the UI **must** render the `MODO DEMO` badge.
- It must cycle through **all** registered markers, never default to one club.
  Hardcoding a single team is the `BUG-01` regression.

---

## 10. Performance budgets

Enforced in the device acceptance run; regressions block the slice.

| Budget | Limit | Why |
|---|---|---|
| Frame work on the UI isolate for detection | **0 ms** | Detection is native. Dart must never decode frames. |
| Time from `ArSearching` to `ArLocked` | ≤ 2 s at 25 % frame fill | ARCore's own detection floor |
| Simultaneous tracked images | 1 | ARCore allows 20; we need one. Fewer = less CPU |
| GLB size per marker | ≤ 4 MB, ≤ 50 k tris | mid-tier Android thermals |
| Reference images in the active DB | 5 logos that score ≥ 75 | Gate is 75, not 90. ARCore allows 20. Still one simultaneous track. |
| Concurrent particle/VFX effects | 1 | Article on low-end devices |

`package:image` is **dev-tooling and test only**. It must not appear in a
runtime code path.

---

## 11. Plugin and native configuration policy

**Ratified detector (D-12):** ARCore/ARKit Augmented Images via
[`ar_flutter_plugin_plus`](https://pub.dev/packages/ar_flutter_plugin_plus),
pinned exactly.

Be aware of the risk this carries and treat it accordingly: it is a young,
low-adoption community fork (single-digit GitHub stars). That is precisely why it
sits behind `ArTracker` (§3) and why the contingency in §12 is pre-authorised.

```yaml
# Exact pin — no caret. A silent minor bump must never reach a student laptop
# mid-demo.
ar_flutter_plugin_plus: 1.1.3
```

Mandatory usage notes, learned the hard way:

- Precompile the image database **before any call that registers
  `trackingImagePaths`**. Attempt #1 never did; passing raw asset paths to
  `onInitialize` without precompiling is a known non-detection path.
  Plugin 1.1.3 cannot precompile until a session exists, and the session is
  created inside `onInitialize`. The legal order is therefore:
  1. `onInitialize(trackingImagePaths: null)` — session only, no images
  2. `precompileImageTrackingDatabase(paths)`
  3. `updateImageTrackingSettings(trackingImagePaths: paths)` — applies the cache
  Calling `precompile` first fails with `Session not initialized`. Do not
  "fix" that by skipping precompile and passing the paths to step 1.
- Pass a physical width for each reference image. ARCore explicitly improves
  detection when real-world size is supplied.
- Plugin 1.1.3 loads a GLB and never ticks Filament `Animator`. Player clips
  (`idle`, `gesto`, `celebracion`) need `tools/patch_filament_clips.ps1` after every
  `flutter pub get`, same rule as the width patch. A missing clip or a missing
  patch returns false from `playClip` and must not drop the session. Do not
  bump the pin. Do not write a matcher.
- Gate model placement on `isFullyTracked` (`AugmentedImage` full tracking
  state). Placing on a `paused` image gives you a model floating at the wrong
  depth.
- Set `continuousImageTracking` and `imageTrackingUpdateIntervalMs` deliberately
  and record the values in the work item.

### Native config — allowed

| Change | Reason |
|---|---|
| `minSdk = 24` | ARCore floor |
| `CAMERA` permission | required |
| `com.google.ar.core` meta-data = `optional` | app still installs on non-AR devices |
| `<package android:name="com.google.ar.core"/>` in `<queries>` | availability check on API 30+ |

### Native config — forbidden without a constitution amendment

| Change | Why |
|---|---|
| `isDebuggable = false` on the **debug** build type | RC-5. Breaks debugging repo-wide |
| Hardcoding `compileSdk` past the Flutter stable default | RC-4 |
| Manual `implementation("com.google.ar:core:x")` | RC-4. Races the plugin's transitive version |
| `org.gradle.java.installations.auto-download=true` | RC-4. Silent JDK provisioning |
| foojay-resolver toolchain plugin | RC-4 |

Any native edit is its own commit, with the reason and a rollback note in the
message.

---

## 12. Pre-authorised contingency

If the device acceptance run (§7) cannot be passed with well-scoring marker
cards, **do not** start writing a custom matcher. That is precisely what
attempt #1 did. Instead implement this pre-approved alternative:

**`HybridMarkerTracker`** — a second `ArTracker` implementation where identity
comes from a small QR/DataMatrix code printed in the corner of the same marker
card (read with `mobile_scanner`), and pose comes from ARCore plane detection
instead of image tracking.

- Identity stays **deterministic** — the code encodes the `Marcador.id` directly.
- The card art is unchanged, so the printed markers stay valid.
- The seam means screens, controller and registry need **zero** changes.

This is the only sanctioned fallback. Anything else requires a constitution
amendment.

---

## 13. Target file layout

```
lib/
  ar/
    ar_tracker.dart               interface + ArDetection + failures
    ar_session_controller.dart     state machine, debounce, error mapping
    ar_session_state.dart          sealed states
    marker_registry.dart           trackerName -> Marcador (exact)
    trackers/
      arcore_image_tracker.dart    ONLY file importing the plugin
      fake_ar_tracker.dart         tests + demo mode
  models/
    marcador_model.dart
  screens/
    ar/
      ar_scan_screen.dart          searching / candidate chrome
      ar_locked_screen.dart        3D + action overlay
      widgets/                     badges, action bar, panels
assets/
  ar_markers.json                  marker metadata
  markers/                         reference images (arcoreimg >= 75)
  models/<marcador_id>/            GLB per marker
test/
  ar/
    ar_session_controller_test.dart
    marker_registry_test.dart
docs/
  ar-postmortem.md
  ar-architecture.md               this file
  ar-marker-guide.md
```

---

## 14. Review checklist for any AR change

- [ ] Only `lib/ar/trackers/` imports the AR plugin (grep in §2 is clean).
- [ ] No similarity score, hash, or tuned threshold decides marker identity.
- [ ] No new state booleans on AR widgets — state lives in `ArSessionState`.
- [ ] Every `ArFailed` path has Spanish copy and an escape to the manual path.
- [ ] Demo content is impossible without `isDemo == true` and the badge.
- [ ] `dispose()` stops the tracker and cancels every subscription.
- [ ] New markers normalized (D-21), scored `arcoreimg eval-img` ≥ 75, and the
      score plus shipped variant recorded in the marker guide §7.
- [ ] Device acceptance table (§7) filled in, including both control rows.
- [ ] No forbidden native config from §11.
- [ ] `flutter analyze` clean on touched files.
