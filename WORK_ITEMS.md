# LMB Plusur — Work Items para Agentes

> Backlog after Constitution **v2.0.0** (decisions D-01…D-20 + professor
> checklist). Each item is a **copy-paste prompt**. One item per branch/PR.
> Format: contexto → tarea → criterios de aceptación → archivos → fuera de alcance.
>
> Theme: **LMB baseball Zona Sur**. “Mundial 2026” in the professor PDF is
> leftover from the old brief — meet those *technical* bars with baseball
> content only (Constitution theme note).

> **AR reset (2026-09-07).** Attempt #1 was abandoned. The old monolithic AR
> items (US-05 … US-08) are replaced by the **AR-00 … AR-07** slices below.
> Each slice is independently verifiable, and the first three need **no plugin
> and no camera** — so the risky native work lands on a foundation that is
> already proven. Before starting any `AR-*` item, read
> [`docs/ar-postmortem.md`](./docs/ar-postmortem.md) and
> [`docs/ar-architecture.md`](./docs/ar-architecture.md).

## Leyenda

| Campo | Valores |
|---|---|
| **Tipo** | 🐛 Bug · 📗 User Story · 🔧 Spike · 🧍 Human task |
| **Prioridad** | 🔴 P0 · 🟠 P1 · 🟡 P2 · 🟢 P3 |
| **Estado** | ☐ Pendiente · ◐ En progreso · ☑ Hecho |

## Índice

| ID | Tipo | Prio | Título | Estado | Checklist map |
|---|---|---|---|---|---|
| US-01 | 📗 | 🟠 P1 | Team list name search (D-10) | ☑ | UI |
| US-02 | 📗 | 🟠 P1 | Abrir experiencia AR from team menu (D-11) | ☑ | AR entry |
| US-03 | 📗 | 🟠 P1 | Last trivia score on device (D-08) | ☑ | Bonus/trivia |
| US-04 | 📗 | 🟡 P2 | Action feedback sounds + visual states | ☑ | UX |
| SP-01 | 🔧 | 🔴 P0 | Flutter-native AR spike (R-01) | ☑ | AR foundation |
| AR-00 | 📗 | 🔴 P0 | Ship the 4 measured markers (≥ 75) into `assets/markers/` | ◐ código ☑ · imprimir ☐ | 3 markers (blocks AR-05) |
| AR-01 | 📗 | 🔴 P0 | `Marcador` data + `MarkerRegistry` — no camera | ☑ | 3 markers |
| AR-02 | 📗 | 🔴 P0 | `ArTracker` seam + session state machine — no plugin | ☑ | AR foundation |
| AR-03 | 📗 | 🔴 P0 | AR scan UI on the state machine (fake tracker) | ☑ | UI / chrome |
| AR-04 | 📗 | 🔴 P0 | Pin plugin + `ArCoreImageTracker` availability probe | ☑ | AR foundation |
| AR-05 | 📗 | 🔴 P0 | Real detection → deterministic lock (kills BUG-01) | ☑ | 3 markers |
| AR-06 | 📗 | 🔴 P0 | In-session 3D anchored on the marker pose | ◐ código · dispositivo ☐ | Buttons / UI |
| AR-07 | 📗 | 🔴 P0 | ≥2 AR action types (anim, info+TTS, …) | ☐ | 2 action types |
| US-09 | 📗 | 🟠 P1 | Simulated live stats in AR / team | ☐ | Actions |
| US-10 | 📗 | 🟠 P1 | Multiple AR modes (galería / trivia / video) | ☐ | Bonus + modes |
| US-11 | 📗 | 🔴 P0 | Video archive UI (remote URLs) | ☐ | Videos |
| US-12 | 📗 | 🔴 P0 | Video filters — allowed set only | ☐ | Filters |
| US-13 | 📗 | 🟠 P1 | Baseball-coherent 3D animations / VFX | ☐ | 15pt effects |
| US-14 | 📗 | 🟡 P2 | Performance pass (load / stability) | ☐ | 15pt perf |
| US-15 | 📗 | 🟡 P2 | Android APK release build | ☐ | Packaging |
| US-16 | 📗 | 🟢 P3 | README product brief for humans | ☐ | Docs |
| DEBT-01 | 🐛 | 🟡 P2 | Remove parallel English domain (`Team`, `TriviaQuestion`) | ☐ | Article IV |
| ~~US-05…US-08~~ | — | — | ~~Old monolithic AR items~~ | ⊘ | Replaced by AR-01…AR-07 |
| ~~BUG-01~~ | — | — | ~~AR mock always Guerreros~~ | ⊘ | Deleted with the mock in AR-03 |

**Human blockers (not agent-solo):** **print** the 4 markers from AR-00 at
≥ 15 cm on matte paper and measure their width (blocks AR-05 only, so agents can
run AR-01…AR-04 in parallel); supply baseball remote video URLs (R-03); author
or generate GLB models (D-03); record explanatory demo video (10pt).

> Marker art is **no longer a blocker** — `arcoreimg` measurement on 2026-09-07
> found four club logos scoring ≥ 75 after normalization (D-20/D-21).

---

# 📗 USER STORIES

## US-01 · 🟠 P1 · Team list name search (D-10) · ☑ Hecho

**Prompt**
```
Contexto: Constitution D-10 requires client-side name search on the team list.
TeamListScreen today lists all Zona Sur clubs with no filter.

Tarea: Add a Spanish search field that filters equipos by nombre (case-
insensitive, accent-tolerant if practical). Empty query shows all teams.
Reuse AppColors / existing list tiles. Keep navigation to TeamMenuScreen.

Criterios de aceptación:
- Typing filters the visible list without leaving the screen.
- Clearing the field restores the full list.
- No backend; filter in memory from DataService data.
- flutter analyze clean on touched files.

Archivos: lib/screens/team_list_screen.dart (and small widget extract if needed)
Fuera de alcance: server search, fuzzy ranking libraries, AR changes.
```

---

## US-02 · 🟠 P1 · Abrir experiencia AR from team menu (D-11) · ☑ Hecho

**Prompt**
```
Contexto: D-11 — manual path must offer “Abrir experiencia AR” that launches
the scanner (optionally hinting the team logo). Full marker AR still requires
a real scan (or labeled demo until AR-05).

Tarea: Add a FeatureCard on TeamMenuScreen that navigates to the AR route,
passing the selected Equipo as a hint argument. AR screen shows Spanish copy
like “Apunta al logo de {nombre}”. Do not auto-complete detection without
camera recognition unless demo mode is explicitly labeled.

Criterios de aceptación:
- Team menu has the new entry, styled like other FeatureCards.
- AR screen receives optional equipo hint and shows it in UI copy.
- Manual path still exposes historia / trivia / highlights as today.

Archivos: lib/screens/team_menu_screen.dart, lib/screens/ar_view_screen.dart,
lib/app.dart or routes if arguments need wiring
Fuera de alcance: real marker tracking (now AR-05), 3D models.
```

---

## US-03 · 🟠 P1 · Last trivia score on device (D-08) · ☑ Hecho

**Prompt**
```
Contexto: D-08 — no logins; may persist only the last trivia score per team
(or globally last score) on device.

Tarea: After trivia results, save the latest score with shared_preferences
keyed by equipo.id. Show “Último puntaje: X” on TeamMenuScreen and/or trivia
entry. Overwrite on each completed run.

Criterios de aceptación:
- Completing trivia updates the stored last score.
- Relaunching the app still shows the last score.
- No account UI.

Archivos: pubspec.yaml, new small service under lib/services/, team_menu and
trivia_results screens
Fuera de alcance: leaderboards, cloud sync, multi-score history.
```

---

## US-04 · 🟡 P2 · Action feedback sounds + visual states · ☑ Hecho

**Prompt**
```
Contexto: Professor requires visual/auditory feedback on actions.

Tarea: Introduce a tiny FeedbackService (short AssetSource sfx + optional
HapticFeedback). Use it on primary FeatureCard taps, trivia answer select,
and AR placeholder buttons. Buttons should show pressed/selected state.
Short Spanish SnackBar where helpful (“Respuesta guardada”, etc.).

Criterios de aceptación:
- At least 2 distinct short sounds bundled under assets/sfx/.
- Primary navigation actions play feedback without being annoying on spam
  (debounce or very short clips).
- Visual pressed/selected states visible on key buttons.

Archivos: lib/services/feedback_service.dart, assets/sfx/, widgets/screens that
wire it
Fuera de alcance: full design rewrite, background music.
```

---

## SP-01 · 🔧 · 🔴 P0 · Flutter-native AR spike (R-01) · ☑ Hecho

Closed 2026-09-07. Outcome: **D-12** ratified ARCore/ARKit Augmented Images via
an exactly-pinned `ar_flutter_plugin_plus` behind the `ArTracker` seam. R-01 and
R-02 resolved (R-02 → **D-20**). Deliverables landed as
[`docs/ar-architecture.md`](./docs/ar-architecture.md),
[`docs/ar-marker-guide.md`](./docs/ar-marker-guide.md) and
[`docs/ar-postmortem.md`](./docs/ar-postmortem.md). The obsolete
`docs/ar-spike.md` from attempt #1 is superseded — its recommendation to
hash-match club logos is the root cause recorded as RC-1/RC-2.

---

# 🥎 AR SLICES (replaces US-05 … US-08)

> Ordering rationale: **AR-01 → AR-03 need no plugin and no camera.** They are
> fully unit-testable, so the state machine and content mapping are proven
> *before* any native risk is introduced. AR-04 adds the dependency and nothing
> else. Only AR-05 turns on real detection. Attempt #1 did all of this at once
> and had no known-good state to fall back to (RC-6).

## AR-00 · 📗 · 🔴 P0 · Ship the 4 measured markers into `assets/markers/` · ◐ Código hecho · falta imprimir

**Agent work COMPLETE (2026-09-07).** Measured, normalized, named, shipped and
re-verified at exit 0. **Only the human printing step remains.**

| Done | |
|---|---|
| ✅ | All 10 logos measured with `arcoreimg` |
| ✅ | `tools/normalize_markers.ps1` + `tools/score_markers.ps1` |
| ✅ | 4 references in `assets/markers/` under their `marcador_*` ids |
| ✅ | Registered in `pubspec.yaml`; `flutter pub get` clean |
| ✅ | Re-scored in place: 100 / 100 / 100 / 90 — exit 0 |
| ✅ | Recorded in `docs/ar-marker-guide.md` §7 |
| ⏳ | **HUMAN:** print at ≥ 15 cm matte, measure width in metres → `anchoMetros` |

There were no stale raw-logo PNGs to delete — `assets/markers/` did not exist.

```
Contexto: Constitution D-13/D-20/D-21 + docs/ar-marker-guide.md §1-§3.
arcoreimg was run against all ten logos. Results (raw -> normalized):
  leones_yucatan    90 -> 100   PASS
  olmecas_tabasco   50 -> 100   PASS
  piratas_campeche  35 -> 100   PASS
  bravos_leon     fail -> 90    PASS  (spare / 4th)
  tigres            75 -> 50    keep RAW if ever needed
  guerreros / diablos              50  too flat
  conspiradores / aguila / pericos  no keypoints at all — never usable

The dominant defect was asset hygiene, not art: 9 of 10 logos were below
ARCore's 300x300 minimum, and 4 were 8bpp indexed PNGs whose transparency
flattened to BLACK, erasing keypoints.

Tarea: Commit the normalized references under their D-20 marker ids and delete
the stale raw-logo PNGs currently loose in assets/markers/.
  1) powershell -ExecutionPolicy Bypass -File tools/normalize_markers.ps1
  2) copy build/markers-normalized/<club>.png to assets/markers/ renamed:
       leones_yucatan.png    -> marcador_estadio_leones.png
       olmecas_tabasco.png   -> marcador_jugador_olmecas.png
       piratas_campeche.png  -> marcador_trofeo_piratas.png
       bravos_leon.png       -> marcador_pelota_bravos.png
  3) register assets/markers/ in pubspec.yaml
  4) re-score assets/markers/ and confirm all PASS

Criterios de aceptación:
- Exactly those 4 files in assets/markers/; no raw club logos left there.
- All 4 score >= 75:
    $env:ARCOREIMG = "$PWD\tools\bin\arcoreimg.exe"
    powershell -ExecutionPolicy Bypass -File tools/score_markers.ps1
  (exit code 0)
- docs/ar-marker-guide.md §7 updated with shipped variant + printed width.
- HUMAN: printed >= 15 cm on MATTE paper, flat, width measured in metres and
  recorded as anchoMetros for AR-01.

Fuera de alcance: any Dart code; marker cards (not needed — no logo below 75 is
required); redesigning logo art.
```

---

## AR-01 · 📗 · 🔴 P0 · `Marcador` data + `MarkerRegistry` (no camera) · ☑ Hecho

**Prompt**
```
Contexto: Constitution Article VI.3/VI.4 + docs/ar-architecture.md §5. Grading
needs >=3 distinct scannable elements with specific content. Identity resolution
must be a deterministic exact lookup — never a similarity score (D-14).

Tarea: Add the Marcador model and assets/ar_markers.json with the three D-20
entries: id, equipoId, tipo (estadio|trofeo|pelota|jugador), titulo, infoTexto,
markerImage, modelAsset, anchoMetros, videoUrl?, animaciones[]. Load it through
DataService. Add lib/ar/marker_registry.dart exposing
`Marcador? resolve(String trackerName)` as a plain exact Map lookup.

Criterios de aceptación:
- JSON parses into typed Dart models; 3 marcadores load.
- MarkerRegistry.resolve returns null for an unknown name — no nearest match,
  no fallback, no scoring, no threshold anywhere in the file.
- Unit test walks ar_markers.json and asserts, for every entry, that the
  markerImage filename stem == the marcador id. (This invariant is what makes
  detection deterministic later.)
- Unit test asserts resolve('no_existe') == null.
- flutter analyze clean; flutter test green.

Archivos: assets/ar_markers.json, lib/models/marcador_model.dart,
lib/ar/marker_registry.dart, lib/services/data_service.dart, pubspec assets,
test/ar/marker_registry_test.dart
Fuera de alcance: camera, plugin, UI, 3D. Placeholder GLB paths are fine (the
files need not exist yet).
```

---

## AR-02 · 📗 · 🔴 P0 · `ArTracker` seam + session state machine (no plugin) · ☑ Hecho

**Prompt**
```
Contexto: docs/ar-architecture.md §3 and §4. Attempt #1 kept AR state in three
loose fields on a StatefulWidget (_detectedTeam / _demoMode / _detectionTimer)
and every unrepresentable combination was a bug. This slice builds the correct
core in pure Dart, with zero native risk.

Tarea:
1) lib/ar/ar_tracker.dart — the ArTracker interface, ArDetection,
   ArTrackerFailure, ArTrackerException, exactly as specified in §3. It must
   NOT import flutter/material.dart.
2) lib/ar/ar_session_state.dart — the sealed states from §4 (ArPreparing,
   ArSearching, ArCandidate, ArLocked, ArLost, ArFailed).
3) lib/ar/ar_session_controller.dart — the state machine with only the legal
   transitions from §4, plus the debounce gate (same trackerName N consecutive
   times inside a 2 s window, default N=2, injectable clock). Reuse the proven
   ImageDetectionGate idea from attempt #1 — it was one of the good parts.
4) lib/ar/trackers/fake_ar_tracker.dart — scripted detections for tests and
   demo mode; cycles ALL registered markers, never defaults to one club.

Criterios de aceptación (all unit tests, no device needed):
- Repeated identical detections: ArSearching -> ArCandidate -> ArLocked.
- Unknown trackerName never leaves ArSearching.
- Two markers alternating never reach ArLocked.
- ArPreparing -> ArLocked is impossible (this is the BUG-01 class of bug).
- Every ArTrackerFailure maps to ArFailed.
- dispose() cancels subscriptions and calls tracker.stop().
- No hash, histogram, score or tuned threshold anywhere in lib/ar/.
- flutter analyze clean; flutter test green.

Archivos: lib/ar/*.dart, lib/ar/trackers/fake_ar_tracker.dart,
test/ar/ar_session_controller_test.dart
Fuera de alcance: any plugin dependency, any camera code, any UI.
```

---

## AR-03 · 📗 · 🔴 P0 · AR scan UI driven by the state machine · ☑ Hecho

**Prompt**
```
Contexto: Article VI.5/VI.6/VI.7 + Article IX. AR-02 landed the state machine;
now give it a face, still on FakeArTracker so it runs on any device or
emulator. This slice DELETES the old Timer mock (closes BUG-01 by removal).

Tarea: Create lib/screens/ar/ar_scan_screen.dart (+ widgets/) that renders one
widget per ArSessionState, and delete lib/screens/ar_view_screen.dart, wiring
AppRoutes.ar to the new screen. Keep the D-11 equipoHint copy
("Apunta al logo de {nombre}"). Reuse AppColors, Poppins, FeatureCard,
PrimaryButton — the old overlay chrome in ar_view_screen.dart is a good
reference for the visual language, so read it before deleting it.
Render the full ArFailed -> Spanish copy table from docs/ar-architecture.md §8,
each with its recovery actions, always including "Elegir equipo manualmente".
Show the MODO DEMO badge whenever ArLocked.isDemo is true.

Criterios de aceptación:
- Every ArSessionState has a distinct rendered state; ArCandidate shows scan
  progress (hits/needed).
- Widget test: pumping a FakeArTracker through to ArLocked shows marker content.
- Widget test: each ArFailed failure shows its Spanish copy AND an escape to the
  manual team path.
- Content cannot appear on screen without ArLocked.
- lib/screens/ar_view_screen.dart is gone; no dangling imports.
- flutter analyze clean; flutter test green.

Archivos: lib/screens/ar/, lib/routes/app_routes.dart, lib/app.dart,
delete lib/screens/ar_view_screen.dart, test/ar/ar_scan_screen_test.dart
Fuera de alcance: plugin, real camera, 3D rendering, AR actions.
```

---

## AR-04 · 📗 · 🔴 P0 · Pin the plugin + `ArCoreImageTracker` availability probe · ☑ Hecho

**Prompt**
```
Contexto: D-12, D-17 and docs/ar-architecture.md §11. Attempt #1's native
config caused "bug: compabilty with android device" (RC-4/RC-5). This slice
introduces the dependency and the platform probe and NOTHING else, so a build
break here is unambiguous.

Tarea:
1) Add the dependency EXACTLY pinned (no caret):  ar_flutter_plugin_plus: 1.1.3
   in its own commit, stating what it pulls in.
2) Native config, own commit, allowed set only: minSdk = 24, CAMERA permission,
   com.google.ar.core meta-data value "optional", com.google.ar.core in
   <queries>. Message must state the reason and the rollback.
3) lib/ar/trackers/arcore_image_tracker.dart implementing ONLY isSupported()
   for now (ARCore availability + camera permission). Everything else throws
   UnimplementedError. This is the only file allowed to import the plugin.

FORBIDDEN (Article VI.8 — each of these broke attempt #1):
- isDebuggable = false on the debug build type
- hardcoding compileSdk past the Flutter stable default
- a manual implementation("com.google.ar:core:x") Gradle dependency
- org.gradle.java.installations.auto-download / foojay-resolver

Criterios de aceptación:
- flutter build apk --debug succeeds; debug build remains debuggable.
- App still launches and every existing screen works (no regressions).
- On a device WITHOUT ARCore, isSupported() == false and the AR route shows the
  arCoreUnavailable copy with the manual-path escape.
- Layering check prints nothing:
  rg -l "ar_flutter_plugin" lib/ | rg -v "^lib/ar/trackers/"
- flutter analyze clean.

Archivos: pubspec.yaml, android/app/build.gradle.kts,
android/app/src/main/AndroidManifest.xml,
lib/ar/trackers/arcore_image_tracker.dart
Fuera de alcance: detection, the image database, 3D, UI changes.
```

---

## AR-05 · 📗 · 🔴 P0 · Real detection → deterministic lock · ☑ Hecho

**Prompt**
```
Contexto: D-12/D-14/D-18. Depends on AR-00 (4 markers scoring >= 75, printed)
and AR-04. This is the slice attempt #1 got wrong by hash-matching logos in Dart
(RC-1/RC-2). Detection is native; Dart only receives a name.

Tarea: Complete ArCoreImageTracker: build the tracking database from
assets/markers/ and stream ArDetection. Mandatory per docs/ar-architecture.md §11:
- call arSessionManager.precompileImageTrackingDatabase(...) BEFORE onInitialize
  (attempt #1 never did this — a known non-detection path)
- pass each marker's real physical width (anchoMetros) to ARCore
- expose isFullyTracked from the tracking state; never report a paused image as
  fully tracked
- record the continuousImageTracking / imageTrackingUpdateIntervalMs values you
  chose, and why, in the PR
Detected image name -> MarkerRegistry.resolve -> debounce -> ArLocked.

FORBIDDEN: any Dart-side image comparison. No package:image at runtime, no
frame decoding, no hashes, no scores, no thresholds, no "prefer this equipo"
tie-breaking. If detection is unreliable, fix the marker art (AR-00) or invoke
the D-19 contingency — do NOT write a matcher.

Criterios de aceptación:
- Device acceptance table from docs/ar-architecture.md §7 filled in and pasted
  into the PR, on a physical Android device with Play Services for AR:
    * each of the 3 printed markers locks onto its OWN content
      (marcador_estadio_leones / marcador_jugador_olmecas / marcador_trofeo_piratas)
    * blank wall for 30 s -> ZERO detections
    * a wrong-club logo (use el_aguila, 0 keypoints) -> ZERO detections
    * time to lock <= 2 s at 25% frame fill
    * if one marker underperforms in print, swap in the spare
      marcador_pelota_bravos rather than accepting a weak target
- Unknown image never crashes and never guesses; session keeps searching.
- Zero Dart frame-processing work on the UI isolate.
- flutter analyze clean; AR-02 unit tests still green.

Archivos: lib/ar/trackers/arcore_image_tracker.dart, assets/markers/,
assets/ar_markers.json (anchoMetros), pubspec assets
Fuera de alcance: 3D placement (AR-06), actions (AR-07), filters.
```

**Closed 2026-09-07.** Human device run: three grading markers locked on their own content. Blank wall and a non-registered club logo triggered nothing. Lock time was not stopwatched.

Recorded tracker settings (`lib/ar/trackers/arcore_image_tracker.dart`):

- `continuousImageTracking: true` — a one-shot emission never reaches the
  debounce gate (N=2), so `ArLocked` would be unreachable.
- `imageTrackingUpdateIntervalMs: 200` — the second hit stays inside the ≤ 2 s
  lock budget without copying a pose onto the UI isolate every frame.

Plugin 1.1.3 creates the session inside `onInitialize` and hardcodes width at
0.2 m. Legal order: null-path `onInitialize` → `precompileImageTrackingDatabase`
→ `updateImageTrackingSettings`. Widths go through `setImageWidths` after
`tools/patch_arcore_image_width.ps1`. `anchoMetros` is still the planned 0.15,
not a measured print.

Device acceptance table (architecture §7). Human, physical Android,
2026-09-07. Lock time was not stopwatched; the human accepted the scans.

| Marker | Detected correctly | Time to lock | False positives in 30 s | Notes |
|---|---|---|---|---|
| `marcador_estadio_leones` | yes | not timed | none reported | human scan |
| `marcador_jugador_olmecas` | yes | not timed | none reported | human scan |
| `marcador_trofeo_piratas` | yes | not timed | none reported | human scan |
| blank wall (control) | none | — | none | human: nothing triggered |
| wrong-club logo (control) | none | — | none | human: nothing triggered |

---

## AR-06 · 📗 · 🔴 P0 · In-session 3D anchored on the marker pose · ◐ Código listo · falta el dispositivo

**Prompt**
```
Contexto: Article VI.2 + D-16. Professor requires 3D on the scanned content
with AR chrome matching the main app. Attempt #1 shipped a WebView
(model_viewer_plus) beside a hash guess and called it AR (RC-3) — a WebView
cannot composite into a camera scene graph and is NOT acceptable here.

Tarea: On ArLocked, attach the marcador's GLB to the tracked image pose using
the tracker's own scene graph (ARNode + GLB via ArTracker.attachModel). Only
place the model once isFullyTracked is true. Overlay Flutter controls
(AppColors / Poppins / FeatureCard / PrimaryButton) with a clear exit. Handle a
missing GLB with a themed fallback, never a red screen.

Criterios de aceptación:
- Each of the 3 markers shows ITS OWN model, anchored to the printed card and
  holding position as the phone moves.
- No model is placed while tracking state is paused.
- Missing/failed GLB -> themed Spanish fallback, session survives.
- Overlay is visually consistent with MainScreen.
- GLBs are <= 4 MB and <= 50k tris.
- model_viewer_plus does not appear anywhere in the AR session path.
- Device run confirms no crash after entering/leaving AR 5 times (dispose is
  correct).

Archivos: lib/ar/trackers/arcore_image_tracker.dart (attachModel),
lib/screens/ar/, assets/models/<marcador_id>/
Fuera de alcance: the action buttons (AR-07), VFX spectacle (US-13).
```

**Code landed 2026-09-07. Device confirmation not run.**

On `ArLocked`, `ArCoreImageTracker.attachModel` places that marker's GLB on
the last fully-tracked image pose and updates the node as new poses arrive.
A missing or failed GLB sets a Spanish overlay and leaves the session up.
`model_viewer_plus` is not used. Placeholder GLBs (one colored box each,
well under 4 MB / 50k tris) live at `assets/models/<marcador_id>/modelo.glb`.
They are not authored stadium/player/trophy art (D-03).

Device checks still open:

- each printed marker shows its own model, stuck to the card as the phone moves
- enter and leave AR 5 times without a crash

---

## AR-07 · 📗 · 🔴 P0 · ≥2 AR action types · ☐ Pendiente

**Prompt**
```
Contexto: Checklist — interactive buttons with >=2 action types (10 pts).

Tarea: In the AR overlay implement at least two of:
1) Activar animación del modelo (idle → celebración/gesto).
2) Información: rotate 360° + panel with datos from marcador.infoTexto + TTS.
3) Reproducir video promocional/histórico (marcador.videoUrl).
4) Efecto VFX simple (particles / light / banner).
Wire FeedbackService (US-04) for audio + visual feedback. Spanish labels.
Actions are available only in ArLocked.

Criterios de aceptación:
- >=2 distinct action types work end-to-end on a real detected marker.
- Info action reads from assets/ar_markers.json — no hardcoded strings, no
  English in user-facing copy.
- Every action gives visual and/or audio feedback and shows a pressed state.
- Actions are unreachable outside ArLocked.
- One VFX at a time; toggling actions repeatedly does not drop the session.
- Controllers (TTS, video, animation) disposed.

Archivos: lib/screens/ar/widgets/, services (tts/video), assets/ar_markers.json
Fuera de alcance: full multi-mode switcher (US-10) unless cheap to stub.
```

---

## US-09 · 📗 · 🟠 P1 · Simulated live stats · ☐ Pendiente

**Prompt**
```
Contexto: Professor asks for realtime stats/results simulated for the prototype.

Tarea: Add a StatsSimulator (timer-based updating scores/innings/hits) shown
in AR and/or team menu. Data is fake, baseball-flavored, Spanish labels.
Not a network API.

Criterios de aceptación:
- Numbers change over time without user spam-tapping.
- UI readable and themed.
- No real LMB API calls.

Archivos: lib/services/stats_simulator.dart, AR/team UI wiring
Fuera de alcance: real sports data feeds.
```

---

## US-10 · 📗 · 🟠 P1 · Multiple AR modes · ☐ Pendiente

**Prompt**
```
Contexto: Experiencias múltiples — galería AR, trivia AR, videos inmersivos.

Tarea: After scan (or from AR hub), let user switch modes: Galería AR
(model focus), Trivia AR (reuse trivia questions overlay), Video inmersivo
(play catalog/marker video in AR chrome). Same visual system. Counts as
bonus/extra mode for grading.

Criterios de aceptación:
- ≥2 modes reachable in one AR session.
- Mode switch has feedback.
- Trivia AR reuses equipo/marcador trivia data where linked.

Archivos: AR hub/mode widgets, routes if needed
Fuera de alcance: building a separate Unity scene graph.
```

---

## US-11 · 📗 · 🔴 P0 · Video archive UI (remote URLs) · ☐ Pendiente

**Prompt**
```
Contexto: D-05/D-07 — baseball video acervo with remote URLs; filters come in
US-12.

Tarea: Add a Videos screen (from main and/or team menu) listing catalog
entries from local JSON (titulo, descripcion, url, equipoId?). Play with
existing video_player patterns. Handle URL failure gracefully. Spanish UI
matching theme.

Criterios de aceptación:
- User can open catalog and play at least one remote URL (use a known public
  sample URL if final list pending R-03).
- Broken URL shows Spanish error, app stable.
- No API server.

Archivos: assets data, models, new screen, app_routes, menus
Fuera de alcance: filter pipeline (US-12), downloading entire files for offline.
```

---

## US-12 · 📗 · 🔴 P0 · Video filters — allowed set only · ☐ Pendiente

**Prompt**
```
Contexto: Constitution Article VII — MUST implement blur, pixelate, thermal,
color adjust, and custom (soft / pastel / high saturation). MUST NOT
implement B&W, grayscale, sepia, exposure, invert.

Tarea: On the video player/editor UI, let user preview apply each allowed
filter family (at least one control per family). Custom section includes
suavizado, pasteles, alta saturación. Guard code reviews: no forbidden
filters in enums/UI. Prefer on-device fragment shaders or image/video frame
processing that keeps playback usable on mid Android phones.

Criterios de aceptación:
- All allowed families reachable in UI with visible effect.
- Forbidden filters absent from UI and code enums.
- Feedback on filter select (US-04 service if present).
- Baseball-themed copy (“Filtros del partido”, etc.).

Archivos: FilterEngine service, video screen widgets, shaders/assets if any
Fuera de alcance: still-photo camera product, uploading filtered video.
```

---

## US-13 · 📗 · 🟠 P1 · Baseball-coherent 3D animations / VFX · ☐ Pendiente

**Prompt**
```
Contexto: 15pt rubric — animations/effects coherent with theme (baseball).

Tarea: Polish at least one celebration animation and one simple VFX
(particles or light burst or banner) tied to AR actions. Keep performance
reasonable (US-14 will tune). Models remain student-supplied placeholders OK.

Criterios de aceptación:
- Animation/VFX clearly baseball-flavored (not soccer Mundial branding).
- Triggered from AR controls.
- Does not drop the AR session on mid-tier Android when toggled a few times.

Archivos: model animation hooks, VFX widget/plugin usage
Fuera de alcance: cinematic cutscenes, Unity.
```

---

## US-14 · 📗 · 🟡 P2 · Performance pass · ☐ Pendiente

**Prompt**
```
Contexto: 15pt — load time and stability on mobile.

Tarea: Profile Android run: splash→main, AR enter, video+filter. Fix obvious
jank (huge images, unbounded rebuilds, missing dispose). Lazy-load heavy
assets. Document before/after notes briefly in docs/performance.md.

Criterios de aceptación:
- No crashes on happy path through scan mock/real + video filter.
- Disposed controllers (video, AR, animation) verified.
- Notes filed for the explanatory video / defense.

Archivos: as needed + docs/performance.md
Fuera de alcance: rewriting entire architecture.
```

---

## US-15 · 📗 · 🟡 P2 · Android APK release build · ☐ Pendiente

**Prompt**
```
Contexto: Packaging gate — APK for Android (IPA optional later).

Tarea: Ensure release signing instructions (debug OK for class if allowed),
flutter build apk succeeds, document install steps in README. Fix any
release-only crashes from Proguard/permissions.

Criterios de aceptación:
- `flutter build apk` succeeds on the project.
- README section: how to install on a phone.
- App launches past splash on a physical Android device or emulator.

Archivos: android/, README.md
Fuera de alcance: Play Store listing, IPA unless time remains.
```

---

## US-16 · 📗 · 🟢 P3 · README product brief · ☐ Pendiente

**Prompt**
```
Contexto: README is still the Flutter template.

Tarea: Replace with short Spanish/English product brief: what LMB Plusur is,
Zona Sur scope, how to run, AR marker testing tips, link to CONSTITUTION /
WORK_ITEMS. No secrets.

Criterios de aceptación:
- Newcomer can run the app from README alone.
- Points to governance files.

Archivos: README.md
Fuera de alcance: marketing site.
```

---

# 🐛 BUGS / DEBT

## BUG-01 · ⊘ Cerrado por diseño

`ArViewScreen`'s timer mock always resolved to `guerreros_oaxaca` or the first
equipo. The screen is **deleted** in AR-03 and the architecture makes the bug
class unrepresentable: content can only render in `ArLocked`, `ArPreparing →
ArLocked` is an illegal transition, and demo mode must cycle all markers
(Article VI.5/VI.6). No separate fix needed — do not reopen.

---

## DEBT-01 · 🐛 · 🟡 P2 · Remove the parallel English domain · ☐ Pendiente

**Prompt**
```
Contexto: Article IV — Spanish domain, English engineering. Known debt #9.
lib/models/team.dart (Team: name/city/history) and
lib/models/trivia_question.dart (TriviaQuestion: prompt) duplicate Equipo and
Trivia in English, and are reachable from lib/data/mock_data.dart and
lib/data/demo_highlights.dart.

Tarea: Consolidate onto the Spanish domain (Equipo, Trivia). Migrate or delete
the mock/demo helpers that depend on the English types. Do not rename any
assets/data.json keys.

Criterios de aceptación:
- Team and TriviaQuestion no longer exist.
- No behaviour change on any screen; existing tests still green.
- Constitution Known debt #9 removed in the same commit.
- flutter analyze clean.

Archivos: lib/models/, lib/data/, any importing screen, CONSTITUTION.md
Fuera de alcance: AR work, renaming JSON keys, redesigning the data layer.
```

---

## Suggested sequence

1. ~~US-01 → US-02 → US-03 → US-04~~ ✅ done (existing shell)
2. **AR foundation, no native risk:** AR-01 → AR-02 → AR-03
   *(human works AR-00 in parallel — it only blocks AR-05)*
3. **AR native:** AR-04 → AR-05 → AR-06 → AR-07 (grading core)
4. US-11 → US-12 (video + filters grading core)
5. US-09 → US-10 → US-13 (depth / bonus — all build on AR-07)
6. DEBT-01 → US-14 → US-15 → US-16 (cleanup / ship)

Do not start AR-04 until AR-01…AR-03 are merged and green. That ordering is the
whole point of the reset: the state machine and content mapping are proven
before native risk enters the repo.

Human in parallel: author + print the 3 marker cards (AR-00), make/get 3 GLBs,
gather baseball video URLs, plan demo recording.
