# Agent handoff — start here

**This file is the session entry point.** A new agent reads this first, works
one item, then **updates this file before finishing** (§6 — mandatory).

**Last updated:** 2026-09-09 · by: US-13 particle burst + drifting balls

---

## 1. What this project is

Flutter 3.47 / Dart 3.13 mobile app. AR fan app for **LMB Zona Sur** (10 Mexican
baseball clubs). A scholar project that must also behave like a real product.

Repo: `C:\Users\T450SCMPTRC\Desktop\LMB_Plusur` — branch **`full-project`**.

## 2. Read before writing any code

These are **binding**, not advisory:

| # | File | What it gives you |
|---|---|---|
| 1 | `CONSTITUTION.md` | Governance, v2.4.8, decisions D-01…D-23 |
| 2 | `AGENTS.md` | How to work here (auto-loaded as a workspace rule) |
| 3 | `WORK_ITEMS.md` | The backlog. Each item's `Prompt` block **is** the spec |
| 4 | `docs/ar-postmortem.md` | Why AR attempt #1 was thrown away (RC-1…RC-7) |
| 5 | `docs/ar-architecture.md` | AR contract: layers, `ArTracker`, state machine |
| 6 | `docs/ar-marker-guide.md` | Marker measurement, scores, print specs |

Don't restate them back to the user. Just follow them.

## 3. Context: AR was reset

A previous branch (`ar-have-too-many-errors`) shipped ~2,000 lines of broken AR
and was abandoned. Its core mistake: it tried to recognize club logos with a
612-line hand-written Dart matcher — perceptual hashes, hue histograms, ~9 tuned
magic thresholds — instead of measuring whether the logos were trackable at all.
Measured later, four of them were. **Never copy code from that branch.**

### Hard rules (full list in `AGENTS.md` → "Hard don'ts")

- Detection is **native**. Dart never decodes camera frames, never uses
  `package:image` at runtime, never computes a similarity score or threshold.
- Marker identity = **exact map lookup** of the tracker's reference-image name.
- Only `lib/ar/trackers/` may import an AR plugin. Check:
  `rg -l "ar_flutter_plugin" lib/ | rg -v "^lib/ar/trackers/"` → must be empty.
- AR state lives in the sealed `ArSessionState`. No detection booleans on widgets.
- No Unity, no backend API, no logins. UI copy in **Spanish**.
- Forbidden video filters: B&W, grayscale, sepia, exposure, invert.
- **One work item per branch/commit.** Native/Gradle edits and dependency
  additions are their own separate commits.

## 4. Current state

**Done**

- US-01…US-04 — team search, AR entry point, trivia last score, feedback sfx.
- AR-04 — `ar_flutter_plugin_plus` pinned
  at **1.1.3** (no caret). It pulls `permission_handler` 12.0.3, `geolocator`,
  `package_info_plus`. No manual `com.google.ar:core` Gradle line.
  Native: `minSdk = 24`, `CAMERA`, ARCore meta-data `optional`, package query.
  The plugin has no Dart availability API, so the probe uses a reflection
  channel in `MainActivity` — not a new AAR.
- AR-05 — `ArCoreImageTracker.start` builds the image database and streams
  `ArDetection`. A capable device uses this tracker, not `FakeArTracker`.
  Demo is only `--dart-define=LMB_AR_DEMO=true`. Settings:
  `continuousImageTracking: true`, `imageTrackingUpdateIntervalMs: 200`.
  Order: null-path `onInitialize` → `precompileImageTrackingDatabase` →
  `updateImageTrackingSettings`. Identity is the tracker name unchanged.
  Human device run: Leones, Olmecas and Piratas locked on their own content.
  Blank wall and a non-registered club logo triggered nothing. Lock time was
  not stopwatched.
- AR-03 — `ArScanScreen` is the AR route. One panel per `ArSessionState`.
  Marker content (`titulo` / `infoTexto`) renders only in `ArLocked`.
  `MODO DEMO` shows while `isDemo` is true. `ArFailed` uses the §8 Spanish
  copy and always includes **Elegir equipo manualmente**. The `Timer` mock
  (`lib/screens/ar_view_screen.dart`) is **deleted**. Do not restore it.
- AR-02 — `ArTracker` seam, sealed `ArSessionState`, `ArSessionController`
  (debounce: same name N times in 2 s, default N=2, injectable clock),
  `FakeArTracker`. No plugin. `ArLocked` is reachable only after a confirmed
  detection. Spanish failure copy lives on `ArFailed.copy` (architecture §8).
  `vector_math` is now a **direct** dependency so `ArDetection.pose` is
  `Matrix4` without importing `material.dart`. Not an AR plugin.
- AR-01 — `Marcador` + `MarkerRegistry`.   `assets/ar_markers.json` loads the
  active D-20/D-23 markers through `DataService.cargarMarcadores()`.
  `resolve` is an exact map lookup keyed by `Marcador.id`. The spare
  (`marcador_pelota_bravos`) is **not** in that JSON — printable only.
  `anchoMetros` is **0.15** (the planned 15 cm print), not a measured width;
  do not treat it as real until the human records the print (gates AR-05).
- AR-06 (code) — On `ArLocked`, `attachModel` places that marker's GLB on the
  last fully-tracked pose and moves the node with later poses. A missing or
  failed file shows Spanish overlay copy; the session stays up. No
  `model_viewer_plus`. Scan-path models: Leones = low-poly stadium, Olmecas =
  low-poly player, Piratas = trophy box. Device hold-to-card and the 5×
  enter/leave run are not done.
- AR-07 (code) — Actions exist only in `ArLocked`. **Celebración** plays
  `celebracion` then idle, and places ~10 drifting baseball VFX nodes.
  **Información** reads `titulo` / `infoTexto`, speaks them (TTS es-MX), and
  runs one 360° yaw. Stadium and trophy `animaciones` are empty. Device
  confirmation not run.
- **D-22 catalog (code)** — 10 static `estadio.glb` + 10 `jugador.glb` under
  `assets/models/<club_id>/`. Shared mesh family from
  `tools/write_lowpoly_glbs.py`. Players: clips `idle` (3 s), `gesto`
  (2.4 s), `celebracion` (2.8 s, arms up). Shared VFX:
  `assets/models/efecto_jonron/modelo.glb` (one stitched baseball ~276 tris;
  Dart spawns many nodes). Stadiums ~764 tris.
  Regenerating overwrites Leones/Olmecas scan copies; Piratas box stays
  from `write_marker_glbs.dart`.
- US-13 — **Done (reopen closed).** `celebracion` + multi-ball in-scene
  VFX (`attachEffect` / `updateEffect` / `clearEffect`, ~2.8 s drift then
  shrink-away) plus screen-space particle chrome (`ArBaseballVfx`). One
  VFX at a time. Device toggle-spam not run.
- US-11 — Video archive loads `assets/videos.json` through
  `DataService.cargarVideos()`. Main = full catalog; team menu = that club.
  Broken URL → Spanish copy. US-12 filters via `FilterEngine`. Sample URLs
  until R-03. Do not restore `DemoHighlights`.
- US-12 — Allowed filter families only. Forbidden set absent.
- AR-00 / D-23 — scan targets are **logos**, not substitute cards. Gate is
  **≥ 75**, not 90. Active: Leones 100, Olmecas 100, Piratas 100, Bravos 90,
  Tigres **raw JPEG** 75, Diablos flame logo **80**, Guerreros shield logo
  **raw 90**, Conspiradores wordmark **raw 100**, Águila crest **raw 100**,
  Pericos wordmark **raw 100**. Old flat Diablos/Guerreros files stay unused.
  Do not normalize Tigres, the Guerreros shield, the Conspiradores wordmark,
  the Águila crest, or the Pericos wordmark. The other Pericos candidates
  were not scored. Device lock for Bravos and Tigres is not run.

**Blocked on the human**

- Measure printed width in metres → `anchoMetros` (JSON still holds the planned
  0.15, not a measurement). Does not block AR-06.
- AR-06 device: hold-to-card + 5× enter/leave. Optional: replace the procedural
  GLBs with nicer art from `docs/model-prompts.md`.
- AR-07 device: on Olmecas, Celebración plays `celebracion` + drifting
  baseballs + particles, then idle; Información speaks and turns once.
  Toggling must not drop the session.
- Print Bravos and the raw Tigres logo at ≥ 15 cm matte and try a lock.
  Those two are in the database but not yet confirmed on a phone.

**Next**

```
US-14: performance pass
```

Debug APK from earlier today does **not** include this session. Rebuild after
both plugin patches before installing.

`AppRoutes.ar` probes ARCore first. Unsupported devices see the existing
failure panel. Capable devices start `ArCoreImageTracker` (camera behind the
chrome). Do not fall back to the fake tracker when that session fails.

## 5. Environment gotchas

- Shell is **PowerShell 5.1**. Chain with `;` — `&&` is invalid. `pwsh` is not
  installed; use `powershell -ExecutionPolicy Bypass -File …`.
- ⚠️ **`flutter test` used to fail** before running anything:
  `Building with plugins requires symlink support.` Fix once with
  `start ms-settings:developers` → enable Developer Mode.
  **2026-09-07 (AR-01):** `flutter test test/ar/marker_registry_test.dart`
  exited 0 (3 tests). The symlink blocker did **not** reproduce. Still run the
  file you care about and report that result — do not assume the full suite
  was run. `flutter analyze` works fine.
- ⚠️ **Android builds need JDK 17**, not the JRE 8 in `JAVA_HOME`, not JDK 11,
  and not Android Studio JBR 21. Gradle matches `languageVersion=17` exactly.
  **2026-09-07:** after a JDK 17 install, `flutter build apk --debug` exited
  green (`app-debug.apk`). **Do not** turn on toolchain auto-download
  (RC-4 / D-17). If the JDK 17 path is lost, `flutter config --jdk-dir=…`.
- The plugin also warns it still applies the Kotlin Gradle Plugin. Flutter
  3.47 built past that warning; a future Flutter will not. Do not bump the
  plugin to silence it — the pin is exact.
- `arcoreimg` lives at `tools/bin/arcoreimg.exe` (git-ignored; re-download from
  the ARCore SDK if missing — see marker guide §4). Score markers with:
  ```powershell
  $env:ARCOREIMG = "$PWD\tools\bin\arcoreimg.exe"
  powershell -ExecutionPolicy Bypass -File tools/score_markers.ps1
  ```
- `FakeArTracker` uses a **sync** detection stream so `emit()` is applied before
  the call returns. Do not `await` a frame to observe a scripted detection.
  The scan screen listens through a `ValueNotifier` — a raw `setState` from
  that sync emit does **not** schedule a Flutter frame.
- `ArLost` is `isFullyTracked: false` on the locked marker. There is no
  background lost-timer. The 2 s debounce window is checked on the next
  detection, not by a `Timer`.
- Never commit `build/`, `.dart_tool/`, `android/.gradle/`, `tools/bin/`.
- `flutter pub get` dirties `windows/flutter/generated_*` with line-ending-only
  noise. Restore with `git checkout -- windows/`.
- Do not re-encode `marcador_estadio_pericos.png`. First candidate scored
  100 raw; the other four were not scored. Ship the raw file.
- Do not re-encode `marcador_estadio_aguila.png`. The raw crest scores 100;
  writing it again as 24-bit PNG dropped it to 90. Same class of surprise as
  Tigres (normalize lowered 75 → 50).
- **D-22 GLBs** come from `python tools/write_lowpoly_glbs.py` (Python 3.10
  is enough; no extra packages). Re-run after mesh edits. `--players-only`
  skips stadiums. Do not regenerate Leones/Olmecas with
  `tools/write_marker_glbs.dart` — that script only writes the Piratas
  trophy box. The player is a joint hierarchy (no skinning). Clips must
  stay named `idle`, `gesto`, and `celebracion`. Designed height ~11.5 cm;
  do not scale it in Dart. `celebracion` is 2.8 s; the pressed state uses
  that length. Native returns to `idle` when the one-shot ends.
  In-scene VFX uses `attachEffect` / `updateEffect` / `clearEffect` with
  `assets/models/efecto_jonron/modelo.glb` (`--efecto-only` to regenerate).
  Screen-space particles live in `ArBaseballVfx` (chrome only).
- ⚠️ **Plugin 1.1.3 never ticks Filament clips.** After every
  `flutter pub get`, re-run both patches (pub restores the unpatched
  plugin). Do not bump the pin. A missing clip or a missing patch returns
  false and must not drop the session:
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools/patch_arcore_image_width.ps1
  powershell -ExecutionPolicy Bypass -File tools/patch_filament_clips.ps1
  ```
- ⚠️ **Plugin 1.1.3 hardcodes reference width at 0.2 m** and `precompile`
  errors with `Session not initialized` if called before any `onInitialize`.
  AR-05 sends `anchoMetros` via `setImageWidths`, which exists only after:
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools/patch_arcore_image_width.ps1
  ```
  Re-run that after every `flutter pub get` (pub restores the unpatched
  plugin). Do not bump the pin. Do not skip precompile. `start()` fails
  closed if the method is missing, so a lock never uses the 0.2 m default
  by accident. Plugin 1.1.3 also never tells Dart about paused images, so
  `ArLost` will not fire from a real session until a later plugin change —
  paused is still never reported as fully tracked.
- **Superseded AR-04 wiring:** a capable device no longer uses
  `FakeArTracker`. That was temporary until AR-05. Demo is
  `--dart-define=LMB_AR_DEMO=true` only.

## 6. Before you finish — update the docs (mandatory)

**A task is not done until the docs match reality.** Context dies when an agent
finishes work and leaves the next one to rediscover it. Every session ends with
this pass:

| Update | When |
|---|---|
| **This file** — §4 state, §7 log, §5 if you hit a new gotcha, and the **Last updated** line | **Always** |
| `WORK_ITEMS.md` — item status (`☐`/`◐`/`☑`) **and** the índice table row | Always |
| `CONSTITUTION.md` — Known debt, Decisions log, **version bump + Last Amended** | Only if a decision or contract changed |
| `docs/ar-architecture.md` | Only if the AR contract changed |
| `docs/ar-marker-guide.md` §7 | Only if markers changed |
| `docs/ar-postmortem.md` | **Append** if you discover a new failure class. Never delete or soften it |
| `README.md` | Only if how-to-run changed |

Rules of thumb:

- If something cost you more than ~15 minutes to discover, write it into §5 or
  §7 so the next agent gets it free.
- If you had to *reverse* an earlier decision, say so explicitly and why — a
  silent correction teaches nobody. (Example: D-20 originally named the three
  worst logos, chosen before anyone measured.)
- Never quietly delete governance. Amend it, with a version bump and rationale.
- Keep §7 to the **10 most recent** entries; trim the oldest.

## 7. Recent session log (newest first, keep 10)

| Date | Change |
|---|---|
| 2026-09-09 | **US-13 polish.** ~10 drifting baseball nodes + shrink-away; screen particles in `ArBaseballVfx`. Seam: `updateEffect(progress)`. |
| 2026-09-09 | **US-13 closed.** `celebracion` clip + in-scene `efecto_jonron` ARNode. D-22 amended. Optional 2D banner is chrome only. Constitution → v2.4.8. |
| 2026-09-09 | **US-13 reopened.** Screen-space burst alone fails the 15pt 3D gate and architecture §6. |
| 2026-09-08 | **US-12 filters.** Preview on the archive player. Allowed: desenfoque, pixelado, térmica, ajuste de color, suavizado, pasteles, alta saturación. Forbidden set absent. Constitution → v2.4.6. |
| 2026-09-08 | **US-11 video archive.** Catalog in `assets/videos.json`. Main and team menu open it. Broken URL shows Spanish copy. Sample remote URLs until R-03. Constitution → v2.4.5. |
| 2026-09-08 | **Pericos wordmark.** First of five candidates. Raw 100. Shipped as-is as `marcador_estadio_pericos`. The other four were not scored. Constitution → v2.4.4. |
| 2026-09-08 | **Águila crest.** Four candidates scored. Swoosh: no keypoints. "A" + eagle head: 20. Wordmark: raw 100, not shipped (+N watermark). Crest: raw 100, shipped as-is as `marcador_estadio_aguila`. Do not re-encode. Constitution → v2.4.3. |
| 2026-09-08 | **Conspiradores wordmark.** First of four candidates. Raw 100. Shipped as-is as `marcador_estadio_conspiradores`. The other three were not scored. Constitution → v2.4.2. |
| 2026-09-08 | **Guerreros shield logo.** First of four candidates. Raw 90. Shipped as-is. The other three were not scored. |
| 2026-09-08 | **Diablos flame logo.** First of four candidates. Raw 60, white-flatten 80. Shipped. The other three were not scored. |

## 8. How to work

Pick **one** item from `WORK_ITEMS.md`, follow its `Prompt` block literally,
satisfy its `Criterios de aceptación`, run `flutter analyze` on touched files,
do the §6 documentation pass, then stop and report.

If a request conflicts with the constitution, or repeats a postmortem root cause
(RC-1…RC-7), **say which one it repeats and stop** instead of complying.

## 9. Current task

> Next: US-14 performance pass. Do not add forbidden video filters.

_(The human edits this line each session. Leave it pointing at the next item
when you finish.)_
