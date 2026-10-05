# Agent handoff — start here

**This file is the session entry point.** A new agent reads this first, works
one item, then **updates this file before finishing** (§6 — mandatory).

**Last updated:** 2026-10-05 · by: BUG-10 portrait orientation

---

## 1. What this project is

Flutter 3.47 / Dart 3.13 mobile app. AR fan app for **LMB Zona Sur** (10 Mexican
baseball clubs). A scholar project that must also behave like a real product.

Repo: `C:\Users\T450SCMPTRC\Desktop\LMB_Plusur` — branch **`full-project`**.

## 2. Read before writing any code

These are **binding**, not advisory:

| # | File | What it gives you |
|---|---|---|
| 1 | `CONSTITUTION.md` | Governance, v2.5.2, decisions D-01…D-27 |
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
  Title renders in `ArLocked` / `ArLost`. `infoTexto` only while
  Información is active. `MODO DEMO` shows while `isDemo` is true.
  `ArFailed` uses the §8 Spanish copy and always includes **Elegir equipo
  manualmente**. The `Timer` mock (`lib/screens/ar_view_screen.dart`) is
  **deleted**. Do not restore it.
- **US-17** — Camera-first chrome. Searching/candidate: center viewfinder +
  short bottom hint. Locked: title + actions; no Salir (back button only).
  Celebración hidden unless `animaciones` contains `celebracion`. `ArLost`
  keeps title/actions and adds “Vuelve a apuntar a {titulo}”. `¡JONRÓN!`
  is a small top chip. Action pressed state lives in `ArChromeSnapshot`
  (`ValueNotifier`) so taps do not `setState` the camera scaffold.
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
  `model_viewer_plus`. Scan-path defaults: Leones = low-poly stadium, Olmecas =
  low-poly player, Piratas = D-22 stadium (BUG-09 replaced the black/glitched
  marker-specific trophy model). Human-tested 2026-10-05: Piratas stadium now
  displays correctly. The post-lock selector still offers stadium and player;
  player visual confirmation, hold-to-card, and the 5× enter/leave run remain
  open.
- AR-07 (code) — Actions exist only in `ArLocked`. **Celebración** plays
  `celebracion` then idle. **Información** reads `titulo` / `infoTexto`, speaks
  them (TTS es-MX), and runs one 360° yaw. Stadium and trophy `animaciones`
  are empty. Device confirmation not run.
- BUG-10 — Flutter requests `portraitUp` before `runApp`; Android and iOS
  platform declarations restrict the app to upright portrait. iPad
  multitasking is disabled so iPad honors its portrait-only orientation list.
  Device-wide settings and the existing vertical UI are unchanged.
- **D-22 catalog (code)** — 10 static `estadio.glb` + 10 `jugador.glb` under
  `assets/models/<club_id>/`. Shared mesh family from
  `tools/write_lowpoly_glbs.py`. Players: clips `idle` (3 s), `gesto`
  (2.4 s), `celebracion` (2.8 s, arms up). Shared VFX:
  `assets/models/efecto_jonron/modelo.glb` (one stitched baseball ~276 tris;
  Dart spawns many nodes). Stadiums ~764 tris.
  Regenerating overwrites Leones/Olmecas scan copies; Piratas box stays
  from `write_marker_glbs.dart`.
- US-13 — **Done (reopen closed).** `celebracion` is a model animation.
  US-20 separates particle effects from animation playback; only one
  in-scene effect can be active at a time. Device toggle-spam not run.
- **US-20 / D-26 — code landed 2026-09-26.** Animated models expose pause /
  resume that freezes the active clip at its frame. Android-only photo capture
  combines the plugin's native AR scene snapshot with a Flutter chrome PNG,
  then saves through MediaStore under
  `Pictures/LMB Plusur`; requires Android 8+, and Android 8–9 asks for legacy
  write permission at capture time. Four independently selectable scene-graph
  presets: Jonrón, Chispas, Confeti, and Polvo del diamante, capped at six
  nodes and one active effect. `tools/patch_filament_clips.ps1` now adds both
  clip ticking and pause/resume. Focused widget coverage is in
  `test/ar/ar_scan_screen_test.dart`. **Physical Android photo capture is
  accepted under BUG-06; animation and effects acceptance remains open.** iOS
  photo capture is explicitly not
  implemented or claimed; if required, scope a separate AVFoundation + Photos
  work item and test on an iPhone.**
- **BUG-06 — done (2026-09-26).** The former Activity-window PixelCopy could
  omit the plugin's separate camera/model `GLSurfaceView`. Capture now uses
  the plugin's native scene snapshot, captures Flutter chrome separately,
  composites on Android, and rejects flat/blank inputs. Analyze, the 12 AR
  widget tests, and debug APK build pass. On connected M2012K10C / Android 13,
  two saved files (`LMB_AR_1790469669646.png`,
  `LMB_AR_1790469677404.png`) were pulled from Pictures and visually inspected;
  both contain the live scene, tracked model, and controls. Device acceptance
  is complete for BUG-06.
- **BUG-07 — done (2026-09-26, device).** Pause appears only after the
  selected model's clip starts successfully. Selecting Jugador starts `idle`
  immediately; changing models clears pause state; static stadiums expose no
  pause control. Confirmed on the physical Android device.
- **BUG-08 — code landed 2026-09-26.** Android pause/hidden parks a lock as
  `ArLost` and asks the tracker to pause the ARCore session; resume restores
  that session on the same surface and waits for a fully tracked detection.
  Chrome taps still must not `setState` the camera scaffold. Native methods
  `pauseSession` / `resumeSession` need
  `tools/patch_arcore_session_lifecycle.ps1` after `pub get`. Widget tests
  wait with a bounded `pump` loop — do not `await` an open `lifecycleGate`
  and do not use `pumpAndSettle` (repeating AR animations never settle).
  **5× lock-screen and background/foreground on a physical Android device
  is still open.** iOS lifecycle is out of scope.
- US-14 — **Done (code).** Splash warm-up (~1.1 s) + logo `cacheWidth`;
  video chrome isolated from filter rebuilds; `DataService` memoization;
  AR camera outside action rebuilds; VFX capped at 6 balls. Notes:
  `docs/performance.md`. Device wall-clock still human-open. Do not
  recompress Águila/Diablos markers without `arcoreimg`.
- US-15 — **Done (build).** `flutter build apk` →
  `build/app/outputs/flutter-apk/app-release.apk` (~70 MB). Release signs
  with debug keystore (class OK). README has run + install steps. Confirm
  splash→main once on a phone. No Play Store keystore in repo. Android launcher
  icons now use a centered square crop of the authored LMB logo in all legacy
  mdpi–xxxhdpi density folders.
- US-16 — **Done, rewritten 2026-09-13.** `README.md` is the public / portfolio
  overview (English, Spanish UI noted). Six phone-sized shots live in
  `docs/screenshots/`. Run + APK + marker tips are still there. Governance
  files are no longer the README hero. Known debt #8 stays cleared.
- US-11 / **R-03** — Video archive loads `assets/videos.json` through
  `DataService.cargarVideos()`. One YouTube highlight per Zona Sur club
  (watch URLs). Main = full catalog; team menu = that club. Playback is
  `youtube_player_iframe` (pulls `webview_flutter`, `url_launcher`).
  `video_player` stays for any leftover MP4. Broken URL → Spanish copy.
  US-12 filters wrap the player; ColorFilter may not tint the YouTube
  WebView on Android. `VideoArchivo.miniaturaUrl` now derives an
  `i.ytimg.com` preview, and YouTube cards/player previews show that image
  before the WebView mounts. CSS-compatible allowed filters are reapplied to
  the iframe during playback
  through the plugin's public WebView controller. Pixelado was removed by the
  v2.5.2 US-12 amendment because it could not be applied consistently to
  YouTube playback. Direct MP4 URLs still use the fully filtered
  `video_player` path. Do not restore `DemoHighlights`. Some clubs share a
  video id (human-supplied list).
- US-12 — Blur, thermal, color adjustment, and custom filters (soft, pastels,
  high saturation) are allowed. Pixelado is removed; forbidden filters remain
  absent.
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
- AR-07 device: on Olmecas, Celebración plays `celebracion`, then idle;
  Información speaks and turns once. Toggling must not drop the session.
- US-20 device (Android 8+): pause/resume idle and celebration at the same
  frame, save a capture to `Pictures/LMB Plusur`, and independently trigger
  each of the four particle presets. Android 7.x should show unsupported copy.
  BUG-07 code coverage now verifies idle pause/resume and model-switch reset;
  physical animation acceptance remains pending until the device is unlocked.
  iOS capture is intentionally not implemented; add a separate native item if
  the professor requires it.
- Print Bravos and the raw Tigres logo at ≥ 15 cm matte and try a lock.
  Those two are in the database but not yet confirmed on a phone.

**Open product / UI gaps (audit 2026-09-09; US-17 closed the chrome list)**

- **BUG-02:** `ArFailedPanel` “Abrir ajustes” and “Instalar” both push the
  team list. **Fixed 2026-09-19:** settings now call
  `permission_handler`/`openAppSettings()`, installation opens the ARCore
  Google Play URL, and only the manual action navigates to teams.
- **BUG-05 fixed 2026-09-21:** Historia reads `historiaImagenUrl` for all ten
  clubs from `assets/data.json` and uses the existing baseball placeholder if a
  remote image fails. Constitution “Feature contracts” table is stale (videos
  still say Planned; markers still say 5 logos).
- **US-18 / D-24:** after a lock, the AR chrome offers **Estadio** or
  **Jugador** from the club's D-22 catalog. The tracker replaces the anchored
  node without restarting the session; the marker model remains the default.
  The choices are compact stadium/baseball icon controls outside the main card.
  **Información** is disabled while **Trivia AR** is active to keep the trivia
  prompt within the available chrome height.
- **US-19 / D-25:** club GLBs are authored Y-up, so the tracker applies a local
  90° X rotation to place them parallel to the scanned logo. Información now
  rotates around the logo normal.
- When **Jugador** is selected from the D-22 catalog, the screen now starts its
  `idle` clip and exposes the player celebration action independently of the
  original marker model's animation metadata. Stadium selection remains static.
- **BUG-03:** Información now stays open after its one presentation turn.
  The turn resets the model yaw only; the user closes the panel with the same
  button or by leaving the locked/lost state.
- **BUG-04:** Video cards no longer start as black rectangles: YouTube
  thumbnails are shown with a safe fallback. CSS-compatible filter chips
  remain active on the YouTube iframe during playback; iframe creation is
  handled with a bounded retry and filter changes reapply after playback
  begins. Direct video URLs retain live filter processing.
- **US-02 refinement:** The selected-team menu no longer repeats
  **Abrir experiencia AR**. The primary shell's **Escanear Logo** card remains
  the scanner entry, while the team menu stays focused on team-specific
  content.

Do not mix BUG-02 with US-09/US-10.

**Next**

```
BUG-08 device 5× lock/background.
Remaining human/device gates: AR-06/07 acceptance, particle effects, printed marker checks.
```

Next: physical Android confirmation for BUG-08 (five lock-screen cycles and
five background/foreground cycles without a black preview).

Release APK path: `build/app/outputs/flutter-apk/app-release.apk`.
Rebuild after all three plugin patches before installing.

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
  that length. Native returns to `idle` when the one-shot ends. Four D-26
  particle meshes live under `assets/models/efecto_*/`; regenerate the three
  additional meshes with `python tools/write_lowpoly_glbs.py --particles-only`.
  Effects are separately selected and capped at **6** scene-graph nodes.
- ⚠️ **Plugin 1.1.3 never ticks Filament clips or pauses them by itself.**
  After every `flutter pub get`, re-run both patches (pub restores the
  unpatched plugin). The clip patch supplies ticking and pause/resume at the
  current frame. Model replacement removes the old active clip; the pause
  control is exposed only after the selected clip starts successfully. Do not
  bump the pin. A missing clip or patch returns false and must not drop the
  session:
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools/patch_arcore_image_width.ps1
  powershell -ExecutionPolicy Bypass -File tools/patch_filament_clips.ps1
  powershell -ExecutionPolicy Bypass -File tools/patch_arcore_session_lifecycle.ps1
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
- Action pressed / notes live in `ArChromeSnapshot` (`ValueNotifier` on
  `ArScanScreen`). Tapping Celebración / Información / an effect must **not**
  `setState` the `Scaffold` that owns `camera.buildSurface()`. Session
  start still `setState`s once to attach the platform view.
- ⚠️ **BUG-08 widget tests must not wait forever.** `pumpAndSettle` never
  returns if an AR `AnimationController` is repeating. `FakeArTracker.lifecycleGate`
  hangs unless the test completes it — leave it null. Do not spin on
  `tester.pump` after `AppLifecycleState.paused`: that state disables frames,
  so an unbounded `runAsync` wait is the hang. Widget tests drive
  `ArScanScreenState.debugHandleAppLifecycle` instead, then `pump` — do not
  `await` that future in widget tests (it can hang the fake async zone). Ignore
  `AppLifecycleState.inactive`; it fires on the way back to `resumed` and
  would pause the camera again.
- US-20 photo capture is Android-only: PixelCopy requires API 26+, and API
  26–28 needs the runtime legacy storage grant. The image is saved through
  MediaStore into `Pictures/LMB Plusur`. No iOS capture implementation or UI
  support is included.
- **Superseded AR-04 wiring:** a capable device no longer uses
  `FakeArTracker`. That was temporary until AR-05. Demo is
  `--dart-define=LMB_AR_DEMO=true` only.
- YouTube archive clips use `youtube_player_iframe` (WebView). Flutter
  `ColorFilter` / `ImageFilter` do **not** tint that platform view on Android.
  The video widget now uses the plugin's public `WebViewController` to apply
  CSS-compatible filters to the iframe. Filters still wrap the widget for MP4
  leftovers. Do not scrape YouTube into `video_player`. After `flutter pub get`,
  re-run the two AR plugin patches.
- **README screenshots (2026-09-13).** `flutter run -d web-server` paints a
  blank page unless a Dart debug client connects. Use `flutter build web`
  and a static server instead. Headless Chrome needs SwiftShader
  (`--use-gl=angle --use-angle=swiftshader`) for Flutter canvaskit.
  Flutter web has no usable semantics tree, so taps are coordinate-based
  at 390×844. Do not shoot the live AR camera for the gallery — web has
  no ARCore. Shots: `docs/screenshots/*.png`.

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
| 2026-10-05 | **BUG-10 portrait orientation.** Flutter requests `portraitUp` before `runApp`; Android and iOS declarations allow upright portrait only. iPad multitasking is disabled to enforce that orientation list. Analyzer, all Flutter tests, and Android debug build pass; iOS build unavailable on Windows. |
| 2026-10-05 | **US-12 amended (v2.5.2).** Removed Pixelado from Article VII, the runtime enum/renderer, archive controls, and YouTube/MP4 filter choices because it could not work consistently on YouTube playback. Removed its preview-only warning and updated US-12, BUG-04, README, and performance notes. Other allowed families and forbidden-filter constraints are unchanged. |
| 2026-10-05 | **BUG-09 device accepted.** Human confirmed the Piratas D-22 stadium GLB displays correctly as the marker default, replacing the black/glitched trophy rectangle. Data and locked-state attachment regressions pass. Player visual confirmation and broader AR-06 hold/enter/leave checks remain open. |
| 2026-09-26 | **BUG-07 done on device.** Pause/resume covers supported clips including idle; static stadiums stay without a fake pause control. |
| 2026-09-26 | **BUG-08 code.** Screen observes `paused`/`hidden`/`resumed` only (not `inactive`). Controller parks `ArLocked` as `ArLost`, re-subscribes detections after tracker resume, and maps a failed restore to `ArFailed(sessionLost)`. Tracker talks to `pauseSession`/`resumeSession` on the pinned plugin after a third post-`pub get` patch. Tests use bounded pumps, not `runAsync` wait-forever loops. Device 5× still open. |
| 2026-09-26 | **BUG-07 code.** Pause/resume now follows a successfully started clip, so Jugador's `idle` is controllable immediately and a failed/static clip cannot expose a misleading control. Model changes clear paused/celebration state before attaching the selected model; revision checks discard stale async clip results. Added direct tracker-seam and widget regressions for idle pause/resume, stadium/player switching, and fresh idle state. |
| 2026-09-26 | **BUG-06 done.** Replaced Activity-window-only PixelCopy (which misses the AR plugin's separate GL surface) with the plugin's native AR-scene snapshot plus a transparent Flutter chrome capture, composed natively before MediaStore save. Added blank-input rejection and pre-snapshot API gating. Analyze, 12 focused AR tests, and Android debug build pass. Two captures from M2012K10C / Android 13 were pulled from Pictures and visually confirmed to contain the live scene, model, and controls. |
| 2026-09-26 | **AR regression triage.** Split three reported US-20 failures into independent pending items: BUG-06 blank gallery captures, BUG-07 pause/resume coverage for supported clips including idle (no new stadium animation), and BUG-08 AR camera recovery after screen lock/background. Ordered one-at-a-time; no implementation changed. |
| 2026-09-26 | **US-20 / D-26.** Added animation pause/resume at the current clip frame, Android PixelCopy → MediaStore AR photos, and four independently triggered scene-graph particle presets (Jonrón, Chispas, Confeti, Polvo). Added bounded GLBs and updated the pinned-plugin patch and governance. `flutter analyze`, all 12 focused AR tests, and `flutter build apk --debug` pass; photo capture later passed physical review under BUG-06, animation/effect device acceptance remains open. |
| 2026-09-21 | **BUG-05.** Added the ten supplied club-history image URLs to `assets/data.json`, mapped `historiaImagenUrl` into `Equipo`, and replaced Historia's generic card with a cached network image plus the existing safe fallback. Added data coverage tests. |

## 8. How to work

Pick **one** item from `WORK_ITEMS.md`, follow its `Prompt` block literally,
satisfy its `Criterios de aceptación`, run `flutter analyze` on touched files,
do the §6 documentation pass, then stop and report.

If a request conflicts with the constitution, or repeats a postmortem root cause
(RC-1…RC-7), **say which one it repeats and stop** instead of complying.

## 9. Current task

> Next: BUG-08 device acceptance — five Android lock-screen cycles and five
> background/foreground cycles with no black preview, duplicate session, or
> crash. The portrait-only orientation request is complete (BUG-10).

_(The human edits this line each session. Leave it pointing at the next item
when you finish.)_
