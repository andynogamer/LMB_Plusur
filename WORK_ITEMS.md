# LMB Plusur — Work Items para Agentes

> Backlog under Constitution **v2.5.3** (decisions D-01…D-27 + professor
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
| AR-07 | 📗 | 🔴 P0 | ≥2 AR action types (anim, info+TTS, …) | ◐ código · dispositivo ☐ | 2 action types |
| US-09 | 📗 | 🟠 P1 | Simulated live stats in AR / team | ☑ | Actions |
| US-10 | 📗 | 🟠 P1 | Multiple AR modes (galería / trivia / video) | ☑ | Bonus + modes |
| US-11 | 📗 | 🔴 P0 | Video archive UI (remote URLs) | ☑ | Videos |
| US-12 | 📗 | 🔴 P0 | Video filters — allowed set without Pixelado or Suavizado | ☑ | Filters |
| US-13 | 📗 | 🟠 P1 | Baseball-coherent 3D animations / VFX | ☑ | 15pt effects |
| US-14 | 📗 | 🟡 P2 | Performance pass (load / stability) | ☑ | 15pt perf |
| US-15 | 📗 | 🟡 P2 | Android APK release build | ☑ | Packaging |
| US-16 | 📗 | 🟢 P3 | README product brief for humans | ☑ | Docs |
| US-17 | 📗 | 🟠 P1 | AR overlay chrome — compact, camera-first | ☑ | UI / chrome |
| DEBT-01 | 🐛 | 🟡 P2 | Remove parallel English domain (`Team`, `TriviaQuestion`) | ☑ | Article IV |
| BUG-02 | 🐛 | 🟠 P1 | ArFailed “Abrir ajustes” / “Instalar” go to teams | ☑ | Failure UX |
| BUG-03 | 🐛 | 🟠 P1 | Keep AR information open until the user closes it | ☑ | AR UX |
| BUG-04 | 🐛 | 🟠 P1 | Restore video thumbnails and visible YouTube filter previews | ☑ | Videos / filters |
| BUG-05 | 🐛 | 🟡 P2 | Show supplied club photos in Historia | ☑ | Historia |
| BUG-06 | 🐛 | 🔴 P0 | Fix blank images saved by AR photo capture | ☑ | AR capture |
| BUG-07 | 🐛 | 🟠 P1 | Pause/resume every supported AR clip, including idle | ☑ | AR animation |
| BUG-08 | 🐛 | 🔴 P0 | Restore AR camera after returning to the app | ◐ | AR lifecycle |
| BUG-09 | 🐛 | 🟠 P1 | Use Piratas' stadium model as the AR default | ☑ | AR model |
| BUG-10 | 🐛 | 🟡 P2 | Lock the app to upright portrait orientation | ☑ | Platform / UI |
| BUG-11 | 🐛 | 🟠 P1 | Brighten and naturalize AR particle effects | ◐ | AR VFX |
| US-18 | 📗 | 🟠 P1 | Select stadium or player model after AR lock | ☑ | AR depth |
| US-19 | 📗 | 🟠 P1 | Lay AR model parallel to scanned logo | ☑ | AR depth |
| US-20 | 📗 | 🟠 P1 | Pause animation, save AR photos, and trigger four independent particle effects | ◐ | AR interaction / capture |
| ~~US-05…US-08~~ | — | — | ~~Old monolithic AR items~~ | ⊘ | Replaced by AR-01…AR-07 |
| ~~BUG-01~~ | — | — | ~~AR mock always Guerreros~~ | ⊘ | Deleted with the mock in AR-03 |

**Human blockers (not agent-solo):** **print** the 4 markers from AR-00 at
≥ 15 cm on matte paper and measure their width (blocks AR-05 only, so agents can
run AR-01…AR-04 in parallel); optional nicer GLB art (low-poly D-22 catalog
already ships); record explanatory demo video (10pt).

> Marker art is **no longer a blocker** — `arcoreimg` measurement on 2026-09-07
> found four club logos scoring ≥ 75 after normalization (D-20/D-21).
>
> **Branch `full-project` (D-22, D-23).** The model catalog is all 10 Zona
> Sur clubs × 2 GLBs. The scan database is the logos that score ≥ 75, not 90:
> Leones, Olmecas, Piratas, Bravos, Tigres raw, Diablos flame, Guerreros
> shield, Conspiradores wordmark, Águila crest, Pericos wordmark. Do not
> add a logo below 75. Do not write a matcher. Do not substitute a marker
> card. Every Zona Sur club now has a scan target.

---

# 📗 USER STORIES

## BUG-05 · 🟡 P2 · Show supplied club photos in Historia · ☑ Hecho

The Historia view now reads `historiaImagenUrl` from `assets/data.json` for all
ten Zona Sur clubs. Remote image failures retain the existing baseball
placeholder instead of leaving the card empty.

## BUG-06 · 🔴 P0 · Fix blank images saved by AR photo capture · ☑ Hecho

**Prompt**
```
Contexto: US-20 / D-26 added Android AR photo capture through PixelCopy and
MediaStore. On a physical Android device, capture reports success and creates
gallery files, but the saved images are blank. The app copied the Activity
window while the pinned AR plugin renders camera/model in a separate
GLSurfaceView; a successful window copy and file write are not proof that the
AR scene was captured.

Tarea: Trace and fix the Android capture/composition path so the saved image
contains the actual live AR camera image, tracked model, and visible Flutter
AR chrome. Preserve the existing Android-only scope, locked-session gating,
Pictures/LMB Plusur destination, explicit unsupported/error feedback, and
MediaStore behavior. Use the pinned plugin's native AR-scene snapshot for its
GLSurfaceView and capture only Flutter chrome separately for composition. Do
not capture/decode camera frames in Dart, rely only on an Activity-window
copy, or turn a blank capture into a success.

Criterios de aceptación:
- On a physical Android 8+ device, the saved gallery image is non-empty and
  visibly contains the camera scene, anchored model, and visible AR controls.
- Verify the result visually after more than one capture; files must not be
  blank/black and capture must not interrupt the AR session.
- Capture failures remain visible to the user and do not create a
  success-shaped result.
- Add focused tests for capture result/error handling at the platform seam;
  retain physical-device image inspection as a required acceptance gate.
- No iOS support is added or implied.
- **Physical acceptance (2026-09-26):** M2012K10C / Android 13. Two new
  captures (`LMB_AR_1790469669646.png`, `LMB_AR_1790469677404.png`) were pulled
  from `Pictures/LMB Plusur` and visually inspected; both show the live scene,
  tracked model, and AR controls without blank regions replacing the capture.

Archivos: `android/app/src/main/kotlin/mx/lmb/plusur/lmb_plusur/MainActivity.kt`,
`lib/ar/`, `lib/screens/ar/`, AR tests, `docs/ar-architecture.md`,
`docs/agent-handoff.md`

Fuera de alcance: iOS capture, video recording, filters, upload, redesign of
the AR screen, or unrelated camera lifecycle changes.
```

## BUG-07 · 🟠 P1 · Pause/resume every supported AR clip, including idle · ☑ Hecho

**Prompt**
```
Contexto: US-20 / D-26 requires pausing the active model animation. Current
acceptance covers the animated player's idle and celebration clips, but pause
behavior must not depend on the selected model being a player or on a
celebration action having run. The current stadium catalog models are static.

Tarea: Make pause/resume apply to any supported clip on the currently selected
AR model, including the standard idle clip, and verify it after model
selection. Preserve the exact-frame freeze/resume behavior through ArTracker.
Do not add an animation to a static stadium GLB: if a selected stadium has no
clip, it must not show a misleading pause control. If a stadium asset exposes
a supported clip, that clip must be pausable too.

Criterios de aceptación:
- For every selected model with an active supported clip, pause freezes that
  clip at its current frame and resume continues from that frame.
- The idle clip can be paused immediately; the user does not need to trigger
  celebration first.
- Switching models does not leave a stale paused state or target the previous
  model's animation.
- Static models with no clip do not expose an enabled/nonfunctional pause
  control.
- Add tracker/widget regression coverage for idle and model changes; verify
  each currently animated model on a physical Android device.
- Animation pause/resume does not stop tracking, change effects, or rebuild the
  camera platform view.
- **Code verification (2026-09-26):** focused tracker/widget tests, `flutter
  analyze`, and `flutter build apk --debug` pass. Physical pause/resume of
  supported clips including idle is accepted on the Android device.

Archivos: `lib/ar/ar_tracker.dart`, `lib/ar/trackers/`,
`lib/screens/ar/`, `lib/screens/ar/widgets/`, `tools/patch_filament_clips.ps1`,
AR tests, `docs/ar-architecture.md`, `docs/agent-handoff.md`

Fuera de alcance: authoring new stadium animations, new clips, particle-effect
changes, photo capture fixes, or AR lifecycle recovery.
```

## BUG-08 · 🔴 P0 · Restore AR camera after returning to the app · ◐ En progreso

**Prompt**
```
Contexto: In a live AR session, briefly pressing Android's power/lock button
or leaving the app and returning can leave the camera preview black. The
anchored model and animations continue, so the AR session and rendered scene
are out of sync after the app lifecycle transition.

Tarea: Handle Android app lifecycle transitions while the AR screen is active
so returning from the lock screen/background restores a live camera preview
and a coherent tracking/model state. Use the existing ArTracker boundary and
the pinned plugin's supported lifecycle behavior; do not create a second
concurrent camera session or bypass the tracker with screen-specific plugin
calls. If the session must restart, cleanly release the old session and
re-establish tracking through the existing state flow.

Criterios de aceptación:
- After locking/unlocking the screen and after backgrounding/foregrounding the
  app, the camera preview becomes live again without navigating away from AR.
- Tracking resumes coherently: the model follows only a fully tracked marker;
  no stale pose is presented as current tracking.
- Repeat each transition at least five times on a physical Android device
  without a black preview, duplicate session, crash, or leaked camera use.
- Lifecycle handling is testable at the app/tracker boundary and does not
  rebuild the camera surface on ordinary AR control taps.
- Surface a clear recoverable AR failure state if native camera/session
  recovery fails; never silently leave a black view presented as working.
- No iOS lifecycle behavior is added unless separately specified.

Archivos: `lib/ar/`, `lib/ar/trackers/arcore_image_tracker.dart`,
`lib/screens/ar/ar_scan_screen.dart`, `android/app/src/main/`, AR tests,
`docs/ar-architecture.md`, `docs/agent-handoff.md`

Fuera de alcance: photo capture corrections, animation feature expansion,
general app-wide lifecycle refactoring, background AR operation, or iOS work.
```

## BUG-09 · 🐛 · 🟠 P1 · Use Piratas' stadium model as the AR default · ☑ Hecho

**Prompt**
```
Context: The Piratas marker's modelAsset points to a marker-specific trophy
GLB that appears as a black/glitched rectangle on device. The D-22 catalog
already contains a stadium and player GLB for Piratas, and D-24 allows the
user to switch between them after the marker locks.

Task: Make the Piratas stadium GLB the marker's default AR model. Keep the
post-lock stadium/player selector and the existing ArTracker/model-placement
flow; do not alter tracking, marker identity, or the D-22 catalog.

Acceptance criteria:
- `marcador_trofeo_piratas` defaults to
  `assets/models/piratas_campeche/estadio.glb`.
- A focused test verifies the marker data and locked-state model attachment
  use that GLB; the selector remains available to switch to the player.
- `flutter analyze` and focused AR/data tests pass.
- Physical-device visual confirmation (user-reported 2026-10-05): the Piratas
  stadium default works correctly. Player-selector visual confirmation and
  broader AR-06 hold/enter/leave checks remain open.

Files: `assets/ar_markers.json`, AR/data tests, `CONSTITUTION.md` Known debt,
`docs/agent-handoff.md`, `WORK_ITEMS.md`

Out of scope: tracker/plugin changes, replacing the D-22 GLBs, orientation
policy, video filters, or unrelated AR lifecycle work.
```

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

## US-02 · 🟠 P1 · Escanear Logo from primary shell (D-11) · ☑ Hecho

**Prompt**
```
Contexto: D-11 — the primary shell offers “Escanear Logo” and launches the
scanner. A selected team already has a team context, so its menu does not
repeat the scanner entry. Full marker AR still requires a real scan (or
labeled demo until AR-05).

Tarea: Keep the primary-shell FeatureCard wired to the AR route. The AR screen
may still receive an optional Equipo hint from other entry points, but the
selected-team menu focuses on team content. Do not auto-complete detection
without camera recognition unless demo mode is explicitly labeled.

Criterios de aceptación:
- Main shell has the scanner entry, styled like other FeatureCards.
- AR screen receives optional equipo hint and shows it in UI copy.
- Manual path still exposes historia / trivia / highlights as today.

Archivos: lib/screens/main_screen.dart, lib/screens/ar_view_screen.dart,
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
`model_viewer_plus` is not used. Scan-path files at
`assets/models/<marcador_id>/modelo.glb`: Leones is the low-poly stadium,
Olmecas is the low-poly biped player (`idle` + `gesto`), Piratas is still the
gold trophy box. Club catalog files live under `assets/models/<club_id>/`.

Device checks still open:

- each printed marker shows its own model, stuck to the card as the phone moves
- enter and leave AR 5 times without a crash

---

## AR-07 · 📗 · 🔴 P0 · ≥2 AR action types · ◐ Código listo · falta el dispositivo

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

**Code landed 2026-09-07. Device confirmation not run.**

On `ArLocked` only, two actions:

1. **Gesto** — plays clip `gesto` on the attached GLB, then the renderer
   returns to `idle`. `idle` starts when the model is placed if
   `animaciones` lists it. Only the Olmecas scan GLB has those clips.
   Stadium and trophy `animaciones` are empty (those files are static;
   the old `celebracion` name was not a real clip). A missing clip shows
   Spanish overlay copy and leaves the session up.
2. **Información** — highlights the panel, speaks `titulo` + `infoTexto`
   from `assets/ar_markers.json` (platform TTS, es-MX, no new plugin), and
   runs one 360° yaw on the tracked pose. A second tap stops speech and
   the spin. One spin at a time.

Plugin 1.1.3 does not tick Filament clips. Re-run
`tools/patch_filament_clips.ps1` after `flutter pub get`. Do not bump the
pin. Scan database is the five logos that score ≥ 75, including Tigres raw.

Device checks still open:

- Olmecas: Gesto moves the player, then idle resumes
- Información speaks the marker text and turns the model once
- toggling either action a few times does not drop the session

---

## US-09 · 📗 · 🟠 P1 · Simulated live stats · ☑ Hecho

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

**Refinamiento 2026-09-19:** Cada actualización representa una aparición al
bate determinista: tres outs por mitad, alta/baja, corredores que avanzan,
carreras por hit y cierre después de la novena cuando el marcador lo permite.
La tarjeta muestra la mitad, outs, hits y `FINAL`.

---

## US-10 · 📗 · 🟠 P1 · Multiple AR modes · ☑ Hecho

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

## US-11 · 📗 · 🔴 P0 · Video archive UI (remote URLs) · ☑ Hecho

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

## US-12 · 📗 · 🔴 P0 · Video filters — allowed set only · ☑ Hecho

**Prompt**
```
Contexto: Constitution Article VII — MUST implement blur, thermal, color
adjust, and custom (pastel / high saturation). Pixelado was removed by the
v2.5.2 amendment because it could not be applied consistently to YouTube
playback. Suavizado was removed by v2.5.3 because it duplicated the blur
family with a weaker setting, rather than adding a distinct treatment. MUST
NOT implement B&W, grayscale, sepia, exposure, or invert.

Tarea: On the video player/editor UI, let user preview apply each allowed
filter family (at least one control per family). Custom section includes
pasteles and alta saturación. Guard code reviews: no forbidden
filters in enums/UI. Prefer on-device fragment shaders or image/video frame
processing that keeps playback usable on mid Android phones.

Criterios de aceptación:
- All remaining allowed families reachable in UI with visible effect.
- Forbidden filters absent from UI and code enums.
- Feedback on filter select (US-04 service if present).
- Baseball-themed copy (“Filtros del partido”, etc.).

Archivos: FilterEngine service, video screen widgets, shaders/assets if any
Fuera de alcance: still-photo camera product, uploading filtered video.
```

---

## US-13 · 📗 · 🟠 P1 · Baseball-coherent 3D animations / VFX · ☑ Hecho

**Code landed 2026-09-09 (reopen closed + particle polish).** Device
toggle-spam not run.

On `ArLocked`:

1. **Celebración** — plays clip `celebracion` (arms up / bat overhead), then
   idle. Spawns ~10 baseball `ARNode`s that drift for ~2.8 s and shrink away.
   Screen-space sparks/confetti + optional ¡JONRÓN! banner reinforce.
2. **Efecto jonrón** — independent in-scene baseball particles. One VFX at a
   time. `updateEffect` each frame; `clearEffect` on leave / toggle off / end
   of oneshot. Not soccer branding.

US-20 adds Chispas, Confeti, and Polvo del diamante as separate selectable
presets and decouples all four effects from animation playback; Celebración
now triggers only its model clip.

D-22 amended: player clips are `idle`, `gesto`, `celebracion`.

**Corrected acceptance (binding):**
- Polish ≥1 celebration animation on the in-session model.
- ≥1 simple **in-scene** VFX on the tracked pose. One VFX at a time.
- Optional 2D banner may reinforce; it is not the VFX.
- Triggered from AR controls in `ArLocked` only. Dispose nodes/controllers.
- No Unity. No WebView as AR. Stay under 4 MB / 50 k tris per GLB.

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

## US-14 · 📗 · 🟡 P2 · Performance pass · ☑ Hecho

**Code landed 2026-09-09.** Device wall-clock timings still human-open;
notes in `docs/performance.md`.

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

**Done in this pass:** video tick no longer rebuilds filters; splash warm-up
(~1.1 s) instead of a fixed 3 s; logo decode capped; DataService cache; AR
camera isolated from chrome rebuilds; VFX node/particle counts lowered;
primary blur sigma lowered. Did **not** re-encode Águila/Diablos markers
(score risk).

---

## US-15 · 📗 · 🟡 P2 · Android APK release build · ☑ Hecho

**Code/docs landed 2026-09-09.** `flutter build apk` produced
`build/app/outputs/flutter-apk/app-release.apk` (~70 MB). Release still signs
with the **debug** keystore (class demos OK). Device install past splash is
human-open once — follow README.

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

**Done in this pass:** clarified debug signing comment in
`android/app/build.gradle.kts`; README run + install + optional keystore notes;
release APK built green. No minify/Proguard to fix. IPA out of scope.
**Packaging refinement 2026-09-19:** Android launcher icons now use the centered
square crop of the authored `assets/images/LMB_plusur.png` in all legacy
mdpi–xxxhdpi densities.

---

## US-16 · 📗 · 🟢 P3 · README product brief · ☑ Hecho

**Done 2026-09-09.** Product + run brief. Known debt #8 cleared;
constitution → **v2.4.9**.

**Updated 2026-09-13.** README rewritten as the public / portfolio overview
(English). Six phone-sized shots in `docs/screenshots/`. AR camera omitted
(web capture + disclaimer). Run / APK / marker tips kept.

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

## US-17 · 📗 · 🟠 P1 · AR overlay chrome — compact, camera-first · ☑ Hecho

**Done 2026-09-09.** Camera-first overlay. Searching/candidate: center
viewfinder + short hint. Locked: title + actions; `infoTexto` only while
Información is active; no Salir. Celebración hidden unless the marker lists
`celebracion`. `ArLost` keeps chrome + re-aim hint. `¡JONRÓN!` is a top
chip. Action state is `ArChromeSnapshot` (no scaffold `setState` on taps).
`flutter analyze` clean; `flutter test test/ar/ar_scan_screen_test.dart`
6 passed.

**Prompt**
```
Contexto: 2026-09-09 UI audit. The locked AR overlay is a large navy card that
covers the camera where the printed marker and GLB sit: always-visible
infoTexto (~2–3 sentences), three action rows, and a duplicate Salir next to
the back button. Stadium/trophy markers still show Celebración, then the
Spanish “no tiene animación” note. Searching is a bottom text block with no
viewfinder. ArLost (architecture §4: keep content + re-aim hint) currently
replaces the locked chrome and hides actions. The ¡JONRÓN! banner sits over
the tracked pose. Action setState rebuilds the Scaffold that owns the
platform view (US-14 isolation incomplete).

Tarea: Make AR chrome camera-first and match AppColors / Poppins / compact
controls (Article IX). Do not change detection, the state machine, or GLBs.

1) ArLocked: thin chrome — title chip + action bar. Show infoTexto only while
   Información is active (expand-in-place or a bottom sheet). Drop the Salir
   button; the existing back IconButton is the exit.
2) Hide Celebración when marcador.animaciones does not contain `celebracion`.
   Keep Efecto jonrón (in-scene VFX works on static GLBs). Do not invent a
   `gesto` button in this slice.
3) ArSearching / ArCandidate: short hint + a center viewfinder reticle. Do
   not cover the middle of the camera with the navy card.
4) ArLost: keep locked chrome (title + actions) and add a re-aim hint
   (“Vuelve a apuntar a {titulo}”). Update widget tests that currently assert
   content disappears.
5) ¡JONRÓN! banner: small top chip, not a scale-burst over the model.
6) Drive action pressed / notes with a ValueNotifier (or equivalent) so
   tapping Celebración / Información / Efecto does not setState the Scaffold
   that holds camera.buildSurface().

Criterios de aceptación:
- Locked overlay no longer shows infoTexto until Información is pressed.
- Stadium/trophy lock does not offer Celebración.
- Searching shows a viewfinder; the camera center stays visible.
- ArLost still shows marker title + actions plus a re-aim hint.
- Back button is the only exit control in ArLocked.
- Widget tests updated; flutter analyze clean on touched files.
- No plugin import outside lib/ar/trackers/. No matcher. No new 3D.

Archivos: lib/screens/ar/, test/ar/ar_scan_screen_test.dart
Fuera de alcance: BUG-02 (failed-panel actions), US-09 stats, US-10 modes,
device hold checks (AR-06/07), marker art, plugin bump.
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

## BUG-02 · 🐛 · 🟠 P1 · Failed-panel recovery actions · ☑ Hecho

**Prompt**
```
Contexto: Architecture §8 lists recovery actions per ArTrackerFailure.
ArFailedPanel always appends “Elegir equipo manualmente” (correct) but
_onAction only special-cases “Reintentar”. “Abrir ajustes” and “Instalar”
both Navigator.pushNamed(AppRoutes.teams) — same as the manual path.
permission_handler is already a transitive dep of the AR plugin.

Tarea: Wire the labelled actions:
- Reintentar → existing onRetry
- Abrir ajustes → Permission.camera / openAppSettings()
- Instalar → launch Play Store for com.google.ar.core (https or market URI)
- Elegir equipo / Elegir equipo manualmente → AppRoutes.teams
Do not put plugin imports in the panel; keep navigation/settings in the
screen or a tiny helper. Spanish labels unchanged.

Criterios de aceptación:
- Widget test: permissionDenied “Abrir ajustes” does not push teams.
- Widget test: arCoreNeedsInstall “Instalar” does not push teams.
- Manual-path button still reaches the team list on every failure.
- flutter analyze clean.

Archivos: lib/screens/ar/widgets/ar_failed_panel.dart,
lib/screens/ar/ar_scan_screen.dart if needed, test/ar/ar_scan_screen_test.dart
Fuera de alcance: US-17 chrome layout, detection, native Gradle.
```

---

## DEBT-01 · 🐛 · 🟡 P2 · Remove the parallel English domain · ☑ Hecho

**Prompt**
```

## US-18 · 📗 · 🟠 P1 · Select stadium or player model after AR lock · ☑ Hecho

**Prompt**
```
Contexto: Once a marker is locked, every Zona Sur club has a stadium and player
GLB in the D-22 catalog. The first marker model remains the default.

Tarea: In the locked AR chrome, let the fan choose Estadio or Jugador. Replace
the tracked node in place without restarting the AR session. Keep model
placement in the tracker scene graph and keep the selector in Flutter chrome.

Criterios de aceptación:
- Selector appears only after ArLocked / ArLost.
- Estadio and Jugador request the selected club's D-22 GLB.
- Model choices use compact stadium/baseball icon controls outside the main card.
- Información is disabled while Trivia AR is active.
- Switching does not stop or recreate the AR session.
- The selected node remains pose-anchored and missing assets fail gracefully.
- flutter analyze and AR tests remain green.
```

## US-19 · 📗 · 🟠 P1 · Lay AR model parallel to scanned logo · ☑ Hecho

**Prompt**
```

## BUG-03 · 🐛 · 🟠 P1 · Keep AR information open until the user closes it · ☑ Hecho

**Prompt**
```
Contexto: Información opened the panel while the model performed one
presentation turn, then the animation completion handler closed the panel.

Tarea: Keep the information panel visible after the turn completes. The user
closes it by pressing Información again or by leaving the locked/lost state.

Criterios de aceptación:
- The info panel remains visible after the presentation turn.
- The presentation yaw resets independently of panel visibility.
- Existing AR actions and state transitions remain unchanged.
- flutter analyze and AR tests remain green.
```
Contexto: The app scans printed team logos. The current upright GLBs appear
perpendicular to the logo plane, which is less natural for this experience.

Tarea: Apply a local 90-degree orientation so club models lie parallel to the
tracked image plane. Keep the model pose anchored to ARCore and rotate
Información around the logo normal.

Criterios de aceptación:
- The authored Y-up model is laid onto the marker image plane.
- Tracking updates continue to move the node with the marker pose.
- Información rotates around the marker normal, not the old world-up axis.
- flutter analyze and AR tests remain green.
```
Contexto: Article IV — Spanish domain, English engineering. Known debt #9.
lib/models/team.dart (Team: name/city/history) and
lib/models/trivia_question.dart (TriviaQuestion: prompt) duplicate Equipo and
Trivia in English, and are reachable from lib/data/mock_data.dart.
`demo_highlights.dart` was removed in US-11.

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

## US-20 · 📗 · 🟠 P1 · AR capture, animation pause, and four independent particle effects · ◐ En progreso

**Prompt**
```
Contexto: Professor review requires control of the running AR animation,
photos saved to the phone gallery, and four particle effects independently
triggerable apart from animation. Constitution D-26 and AR architecture §§3, 6, 10,
and 11 define the amended contract. D-05 permits only this scan-locked AR
snapshot; the video + filters feature remains unchanged.

Tarea:
1) On an animated model after ArLocked, add a pause/resume control that freezes
   the currently playing clip at its exact frame and resumes from that frame.
   Keep this in the ArTracker seam; do not rebuild the platform camera view.
2) Add an Android-only AR photo control after ArLocked. Capture the complete
   AR window (camera, tracked model, and visible AR chrome) and save it to
   Pictures/LMB Plusur via MediaStore. API 26+ is supported; API 24–25 must
   show an explicit unsupported message. Handle Android 8–9 legacy write
   permission only when capture is invoked. Show success/failure feedback.
3) Provide four separate selectable in-scene particle effects:
   Jonrón (baseball burst), Chispas (gold sparks), Confeti (team-color
   confetti), and Polvo del diamante (infield dust). Each has its own
   appearance/motion preset and control; only one may be active. Effects are
   triggered independently and never implicitly by an animation. Keep each
   effect to at most 6 scene-graph nodes and clear it on deselect/leave.
4) Implement through ArTracker and the existing tracker scene graph. Do not
   import the AR plugin in UI, capture/decode camera frames in Dart, or add an
   unapproved image-matching path. No iOS capture is included or implied.

Criterios de aceptación:
- The animated player can be paused during idle or celebration and resumes
  from the same animation frame; static models do not expose pause.
- AR photo capture is available only after a confirmed lock. On Android 8+,
  a device test finds a new image in Pictures/LMB Plusur containing the camera,
  anchored model, and visible AR chrome. Android 7.x receives clear Spanish
  unsupported copy. Permission denial/save failure is visible and does not
  terminate the AR session.
- All four named effects can be triggered individually without starting or
  changing a model animation. Switching effects leaves no previous effect
  nodes attached, does not exceed 6 particle nodes, and keeps the session live.
- Particle colors stay bright and hue-faithful, and each effect follows its
  distinct time-based path with a clear fade-out rather than remaining dark or
  static.
- The AR camera platform view is not rebuilt by action taps. No UI advertises
  the Android-only photo path on iOS.
- Widget/unit tests cover paused/resumed clip requests, all four effect
  selections, effect clearing, locked-only photo control, and capture
  success/failure feedback through a fake tracker.
- flutter analyze and focused AR tests pass. Physical Android validation of
  saved gallery output remains required; no iOS acceptance is claimed.

Archivos: `lib/ar/ar_tracker.dart`, `lib/ar/trackers/`, `lib/screens/ar/`,
`lib/screens/ar/widgets/`, `android/app/src/main/`, `tools/` (plugin clip
patch), `assets/models/` (lightweight effect particles), AR tests,
`CONSTITUTION.md`, `docs/ar-architecture.md`, `docs/agent-handoff.md`

Fuera de alcance: iOS photo capture, general-purpose camera/gallery routes,
video capture or filters, cloud upload, additional animation clips, more
than one simultaneous effect, and changes to the marker database.
```

## Suggested sequence

0. **US-20 regressions, one item per branch:** ~~BUG-06~~ → ~~BUG-07~~ → BUG-08
   (photo output accepted → pause coverage accepted → camera lifecycle recovery).
1. ~~US-01 → US-02 → US-03 → US-04~~ ✅ done (existing shell)
2. **AR foundation, no native risk:** AR-01 → AR-02 → AR-03
   *(human works AR-00 in parallel — it only blocks AR-05)*
3. **AR native:** AR-04 → AR-05 → AR-06 → AR-07 (grading core)
4. US-11 → US-12 (video + filters grading core)
5. US-09 → US-10 → US-13 (depth / bonus — all build on AR-07)
6. ~~DEBT-01 → US-14 → US-15 → US-16~~ US-14…US-20 core implementation
   landed. BUG-07 pause/resume is accepted on device. After BUG-08,
   continue the existing backlog:
   **BUG-02** (failed actions), then US-09 / US-10 / DEBT-01.

Do not start AR-04 until AR-01…AR-03 are merged and green. That ordering is the
whole point of the reset: the state machine and content mapping are proven
before native risk enters the repo.

Human in parallel: author + print the 3 marker cards (AR-00), make/get 3 GLBs,
gather baseball video URLs, plan demo recording.

## BUG-04 · 🐛 · 🟠 P1 · Restore video thumbnails and visible YouTube filter previews · ☑ Hecho

**Prompt**
```
Contexto: El catálogo R-03 usa URLs de YouTube dentro de un WebView.
El archivo mostraba tarjetas negras porque el póster no usaba una miniatura,
y los filtros Flutter no pueden pintar encima del PlatformView de YouTube en
Android.

Tarea: Derivar la miniatura de cada URL de YouTube y usarla en el póster y en
la vista previa del reproductor. Mantener los filtros permitidos visibles y
funcionales sobre esa vista previa. Aplicar los filtros compatibles con CSS al
iframe de YouTube durante el playback mediante el WebViewController público.
No descargar, extraer ni retransmitir videos de YouTube. Mantener el pipeline
de video_player filtrable para URLs directas.

Criterios de aceptación:
- Las tarjetas del archivo muestran la miniatura de YouTube, con fallback
  estable si la red o la URL fallan.
- Al seleccionar un filtro permitido antes de reproducir, el efecto se ve
  sobre la miniatura filtrada.
- Al pulsar reproducir, los filtros CSS compatibles permanecen activos en el
  iframe.
- No se agregan filtros prohibidos ni una API/backend.
- flutter analyze y las pruebas de videos pasan.
```

**Hecho 2026-09-19; actualizado por la enmienda US-12 v2.5.2:**
`VideoArchivo.miniaturaUrl` deriva la URL `i.ytimg.com`, el archivo usa
miniaturas reales con fallback, y `HighlightVideoPlayer` muestra la miniatura
filtrable antes de montar el WebView de YouTube. Los filtros permitidos
compatibles con CSS permanecen en el iframe durante la reproducción. URLs
directas siguen usando `video_player` y el pipeline de filtros completo.

## BUG-10 · 🐛 · 🟡 P2 · Lock the app to upright portrait orientation · ☑ Hecho

**Prompt**
```
Contexto: LMB Plusur's layouts are designed for portrait. Landscape
orientation makes the app behave strangely.

Tarea: Keep this app in upright portrait orientation on Android and iOS.
Apply the lock only to LMB Plusur, not to device-wide settings. Preserve the
existing vertical UI and avoid unrelated native configuration changes.

Criterios de aceptación:
- Flutter requests `DeviceOrientation.portraitUp` before displaying the app.
- Android's main activity is locked to portrait.
- iPhone and iPad supported orientations contain upright portrait only; iPad
  multitasking is disabled if required to enforce that orientation.
- No landscape or upside-down portrait orientation is enabled.
- No AR or video-filter behavior changes.
- `flutter analyze`, `flutter test`, and an Android debug build pass; report
  that iOS cannot be built locally when validation runs on Windows.

Archivos: `lib/main.dart`, `android/app/src/main/AndroidManifest.xml`,
`ios/Runner/Info.plist`, `WORK_ITEMS.md`, `docs/agent-handoff.md`.
Fuera de alcance: device-wide settings, layout redesign, AR behavior, and
video filters. The native orientation entries can be rolled back independently
from unrelated platform configuration.
```

**Hecho 2026-10-05:** Flutter requests upright portrait before `runApp`;
Android's main activity and iOS supported orientations also restrict the app
to portrait. iPad multitasking is disabled so iPad orientation restrictions
are honored. No layout, AR, or filter behavior changed.

## BUG-11 · 🐛 · 🟠 P1 · Brighten and naturalize AR particle effects · ◐ Código listo

**Prompt**
```
Contexto: Physical review reports that all four US-20 in-scene particle
effects look dark, oddly colored, or too static. Keep the existing four named
presets, six-node maximum, and one-effect-at-a-time tracker contract.

Tarea: Improve material brightness and preserve each preset's intended color.
Replace linear placeholder drift with time-based, preset-specific trajectories:
baseball/sparks arc and fall, confetti flutters and descends, and infield dust
spreads low. Grow particles into view and fade them before the effect ends.
Keep the implementation in the tracker scene graph and its procedural GLB
generator; do not add nodes or screen-space substitutes.

Criterios de aceptación:
- All four generated effect materials use bright, readable colors under scene
  lighting; colors remain coherent with the named effect.
- Motion is distinct and time-based per preset; no preset is a static cluster
  or an identical linear drift.
- Particles scale in and fade out; six-node / one-effect limits still hold.
- Tests cover representative trajectories and lifecycle; `flutter analyze` and
  focused AR tests pass.
- Inspect all four effects on a physical Android AR session; report any device
  rendering limitation rather than claiming visual acceptance from unit tests.

Archivos: `tools/write_lowpoly_glbs.py`, `assets/models/efecto_*/modelo.glb`,
`lib/ar/particle_motion.dart`, `lib/ar/trackers/arcore_image_tracker.dart`,
AR tests, `docs/ar-architecture.md`, `docs/agent-handoff.md`

Fuera de alcance: ARCore/plugin/native changes, camera or marker changes,
screen-space VFX, increasing particle counts, animation changes, or video
filters.
```

**Código actualizado 2026-10-05:** Brightened the vertex palettes and added
material emission to the four generated GLBs. Tracker motion now uses
preset-specific velocity, acceleration, flutter/spin, per-particle lifetime,
scale-in, and fade-out. Physical Android visual acceptance remains open.
