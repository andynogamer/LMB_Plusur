# Agent handoff — start here

**This file is the session entry point.** A new agent reads this first, works
one item, then **updates this file before finishing** (§6 — mandatory).

**Last updated:** 2026-09-07 · by: full-project docs session

---

## 1. What this project is

Flutter 3.47 / Dart 3.13 mobile app. AR fan app for **LMB Zona Sur** (10 Mexican
baseball clubs). A scholar project that must also behave like a real product.

Repo: `C:\Users\T450SCMPTRC\Desktop\LMB_Plusur` — branch **`full-project`**.

## 2. Read before writing any code

These are **binding**, not advisory:

| # | File | What it gives you |
|---|---|---|
| 1 | `CONSTITUTION.md` | Governance, v2.3.0, decisions D-01…D-22 |
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
- AR-01 — `Marcador` + `MarkerRegistry`. `assets/ar_markers.json` loads the
  three active D-20 markers through `DataService.cargarMarcadores()`.
  `resolve` is an exact map lookup keyed by `Marcador.id`. The spare
  (`marcador_pelota_bravos`) is **not** in that JSON — printable only.
  `anchoMetros` is **0.15** (the planned 15 cm print), not a measured width;
  do not treat it as real until the human records the print (gates AR-05).
- AR-06 (code) — On `ArLocked`, `attachModel` places that marker's GLB on the
  last fully-tracked pose and moves the node with later poses. A missing or
  failed file shows Spanish overlay copy; the session stays up. No
  `model_viewer_plus`. Placeholder boxes are in
  `assets/models/<marcador_id>/modelo.glb` (not authored D-03 art). Device
  hold-to-card and the 5× enter/leave run are not done.
- AR-00 (code half) — 4 ARCore reference images in `assets/markers/`, registered
  in `pubspec.yaml`, all scoring ≥ 75:

  | Marker | Score | In active DB |
  |---|---|---|
  | `marcador_estadio_leones` | 100 | ✅ |
  | `marcador_jugador_olmecas` | 100 | ✅ |
  | `marcador_trofeo_piratas` | 100 | ✅ |
  | `marcador_pelota_bravos` | 90 | ➖ printable spare only |

  Unusable: `tigres` 75 raw only (never normalize it) · `guerreros`/`diablos` 50
  · `conspiradores`/`el_aguila`/`pericos` produce **zero keypoints**.

**Blocked on the human**

- Measure printed width in metres → `anchoMetros` (JSON still holds the planned
  0.15, not a measurement). Does not block AR-06.
- Generate the D-22 catalog: 10 static `estadio.glb` + 10 animated
  `jugador.glb`. Prompts in `docs/model-prompts.md`. Do not add the other
  seven logos to the scan database.

**Next**

```
human: 20 GLBs from docs/model-prompts.md
```

Debug APK from earlier today does **not** include this session. Rebuild after
the width patch before installing.

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
| 2026-09-07 | **D-22 / branch `full-project`.** Model catalog is all 10 clubs × stadium (static) + player (`idle`, `gesto`). Scan set stays D-20. Not a matcher. Constitution → v2.3.0. |
| 2026-09-07 | **AR-06 code.** `attachModel` places a per-marker GLB on the fully-tracked pose. Missing/failed GLB → Spanish overlay, session stays up. No WebView. Device hold/dispose checks not run. |
| 2026-09-07 | **AR-05 accepted.** Human: Leones, Olmecas and Piratas locked. Blank wall and a non-registered club logo triggered nothing. Lock time not stopwatched. Next is AR-06. |
| 2026-09-07 | **AR-05 human scan.** Leones, Olmecas and Piratas each locked on a physical device. Control rows not run. Time to lock not timed. |
| 2026-09-07 | **AR-05 code.** Real tracker starts a session; identity is the ARCore name. Continuous tracking 200 ms so debounce can lock. Width patch required (`tools/patch_arcore_image_width.ps1`) because 1.1.3 hardcodes 0.2 m. Tests: 21 passed (detection event + session + scan + registry). Device table **not** filled. Constitution → v2.2.2. Architecture §11 order clarified (null-path init, then precompile). |
| 2026-09-07 | **AR-04 APK green.** Human installed JDK 17. `flutter build apk --debug` built `app-debug.apk`. The earlier failure was a missing JDK 17 toolchain, not the native config. KGP warning from the plugin is still only a warning. Device install and the no-ARCore path were not run. |
| 2026-09-07 | **AR-04 probe.** Pinned `ar_flutter_plugin_plus: 1.1.3`. Native allowed set only (`minSdk` 24, CAMERA, ARCore optional, package query). `ArCoreImageTracker` implements `isSupported` only. First debug APK failed on missing JDK 17. Did not enable foojay. |
| 2026-09-07 | **AR-03.** `ArScanScreen` replaces the Timer mock (file deleted). One panel per `ArSessionState`; marker content only in `ArLocked`; `MODO DEMO` + **Elegir equipo manualmente** on every failure. Tests: 3 passed (`ar_scan_screen_test.dart`). Constitution known debt → v2.2.1 (no rule change). |
| 2026-09-07 | **AR-02.** `ArTracker` / `ArDetection` / failures, sealed session states, `ArSessionController` + debounce gate, `FakeArTracker` (cycles every registered reference, never a default club). Tests: 11 passed (`ar_session_controller_test.dart`). Promoted `vector_math` to a direct dependency for `Matrix4` — analyze forbids an undeclared import; still no AR plugin. |
| 2026-09-07 | **AR reset governance.** Attempt #1 abandoned. Wrote `ar-postmortem.md`, `ar-architecture.md`, `ar-marker-guide.md`; rewrote Article VI into 11 enforceable clauses; ratified D-12…D-20; split monolithic US-05…US-08 into slices AR-00…AR-07. Constitution → v2.0.0. Added `.cursor/rules/`. |

## 8. How to work

Pick **one** item from `WORK_ITEMS.md`, follow its `Prompt` block literally,
satisfy its `Criterios de aceptación`, run `flutter analyze` on touched files,
do the §6 documentation pass, then stop and report.

If a request conflicts with the constitution, or repeats a postmortem root cause
(RC-1…RC-7), **say which one it repeats and stop** instead of complying.

## 9. Current task

> Generate the **D-22** models from `docs/model-prompts.md` (20 GLBs). Do not
> add unmeasured logos to the scan database. Do not write a matcher.

_(The human edits this line each session. Leave it pointing at the next item
when you finish.)_
