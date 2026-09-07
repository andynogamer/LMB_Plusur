# AGENTS.md — LMB Plusur

Ambient rules for coding agents. Governance is in
[`CONSTITUTION.md`](./CONSTITUTION.md). **Read that file first.**

Flutter-first mobile app. Stay in Dart/`lib/` unless the active spec opens
native Android/iOS or an AR plugin integration.

---

## What this repository is

LMB Plusur — AR fan app for **LMB Zona Sur** (scholar + product rigor). Scan
markers for AR; or pick a team by name. Video archive with **allowed** filters,
trivia, simulated stats. **No Unity. No API. No logins.**

| Path | What it is |
|---|---|
| `CONSTITUTION.md` | Non-negotiable principles + decisions log (v2.0.0). |
| `AGENTS.md` | This file. |
| `WORK_ITEMS.md` | Backlog as copy-paste agent prompts. |
| `docs/ar-postmortem.md` | Why AR attempt #1 failed. **Read before any AR work.** |
| `docs/ar-architecture.md` | Binding AR contract: layers, `ArTracker`, state machine. |
| `docs/ar-marker-guide.md` | How to author markers ARCore can actually track. |
| `lib/` | Flutter app. |
| `assets/data.json` | Canonical team content (10 clubs). |
| `assets/` | Images, future markers / models / sfx. |
| `tools/` | Dev scripts (e.g. `score_markers.ps1`). |
| `pubspec.yaml` | Dependencies — do **not** enable Unity widget. |
| `test/` | Flutter tests (thin today). |
| `README.md` | Human run docs (still template). |

---

## Spec-anchored workflow

1. Read `CONSTITUTION.md` (especially Decisions log + grading checklist).
2. **If the item touches AR**, also read `docs/ar-postmortem.md` and
   `docs/ar-architecture.md` before writing code. Non-optional.
3. Take **one** item from `WORK_ITEMS.md`; the `Prompt` block is the spec.
4. Implement only that item. One item per branch / PR / commit.
5. Update constitution/data if the domain contract changes.
6. Do not mix bugfix + feature. Do not expand league scope.
7. Finish by running the relevant review checklist (Article VI.9 /
   `docs/ar-architecture.md` §14 for AR).

If the request conflicts with the constitution, **stop and ask**.

If a request would repeat a postmortem root cause (RC-1 … RC-7), **stop and say
which RC it repeats** instead of complying.

---

## Current phase — AR reset (branch `fresh-start`, post D-01…D-20)

**AR attempt #1 was abandoned.** Branch `ar-have-too-many-errors` is kept only
as evidence for `docs/ar-postmortem.md`. Do **not** cherry-pick code from it
without checking the postmortem first — most of it is the anti-pattern.

State of the tree:

- UI shell, historia, trivia, last-score persistence, feedback sfx: **present**
  (US-01 … US-04 done).
- `lib/ar/` **does not exist yet.** Building it is the current focus.
- `lib/screens/ar_view_screen.dart` is a pre-reset `Timer` mock. It gets
  **replaced**, not patched.
- No AR dependency in `pubspec.yaml`. Adding one is its own work item.
- **Markers are solved (2026-09-07).** `arcoreimg` measurement found four club
  logos scoring ≥ 75 after normalization, so ARCore can track the real logos —
  no custom matcher, no ML classifier, no redesigned art:
  `leones_yucatan` 100 · `olmecas_tabasco` 100 · `piratas_campeche` 100 ·
  `bravos_leon` 90 (spare). See D-20/D-21 and `docs/ar-marker-guide.md` §1.
  `conspiradores`, `el_aguila` and `pericos` yield **zero keypoints** and can
  never be direct targets. Remaining work is AR-00: commit the normalized PNGs
  under their `marcador_*` ids and print them.
- Video filters: not started (graded).
- Primary device under test: **Android**, physical, with Play Services for AR.

Suggested order: `WORK_ITEMS.md` index — AR foundation slices (AR-01 →) before
any AR feature work, then filters, then bonus/polish/APK.

### Local environment notes (verified 2026-09-07)

- Flutter **3.47.1** stable / Dart **3.13.1**. `flutter analyze` is clean.
- Shell is **PowerShell 5.1**; `pwsh` (PowerShell 7) is **not** installed. Use
  `powershell -ExecutionPolicy Bypass -File …` for repo scripts. Chain commands
  with `;` — `&&` is not valid in this shell.
- ⚠️ **`flutter test` currently fails on this machine**, before running any test:
  `Building with plugins requires symlink support. Please enable Developer Mode.`
  Fix once with `start ms-settings:developers` → enable Developer Mode. Until
  then the unit-test acceptance criteria in AR-01/AR-02 cannot be verified, so
  do not report them as passing.
- `arcoreimg` is not installed yet; `tools/score_markers.ps1` exits 2 until the
  ARCore SDK is downloaded (see `docs/ar-marker-guide.md` §4).

---

## Language

- Agent docs: English.
- UI + JSON domain: **Spanish**.
- Dart types/files MAY stay English (`Equipo`, `ArViewScreen`).
- Do not rename JSON keys to English.

---

## Engineering defaults

- Named routes in `lib/routes/app_routes.dart`.
- Reuse `AppColors`, Poppins, `AppHeader`, `FeatureCard`, etc.
- Load content through services/models — no hardcoded club lists in widgets.
- Facades for AR (`ArTracker`), filters, feedback, simulated stats.
- Last trivia score only via local persistence — no accounts.
- `flutter analyze` on touched code when practical.
- Dispose everything you create: controllers, stream subscriptions, AR sessions.
- Pin AR plugin versions exactly (no caret). Other deps may use carets.
- Don't extend `models/team.dart` or `models/trivia_question.dart` — they are a
  parallel English domain slated for removal (Article IV, Known debt #9).
- **Forbidden video filters must never appear** (B&W, grayscale, sepia,
 exposure, invert). See Constitution Article VII.

## Scope discipline

One work item per branch/PR/commit. Attempt #1 put three items and two
firefighting commits on one branch — 1,974 insertions with no bisectable
known-good state, so all of it had to be thrown away.

- If a slice cannot be verified on its own, it is too big. Split it.
- Native/Gradle edits are a **separate commit** with reason + rollback note.
- Adding a dependency is a **separate commit**. Say why, and what it pulls in.
- Do not mix a bugfix with a feature.

---

## AR (ratified — read `docs/ar-architecture.md` before coding)

Flutter-native only. ARCore/ARKit Augmented Images for detection, tracker scene
graph for in-session 3D, Flutter widgets for all overlays. ≥3 distinct markers
for grading. AR chrome matches main UI. Manual team path opens the scanner via
**Abrir experiencia AR** — do not fake full marker AR.

**The one rule:** Flutter decides *what to show*; the platform tracker decides
*what is there*. Neither does the other's job.

### Hard don'ts (each one broke attempt #1)

| Don't | Instead |
|---|---|
| Write an image matcher in Dart — hashes, hue histograms, "edge energy", weighted scores, tuned thresholds | Let the tracker report a reference-image name; resolve it via exact map lookup in `MarkerRegistry` |
| Decode camera frames in Dart / use `package:image` at runtime | Detection is native. `package:image` is dev-tooling and tests only |
| Assume a target works, or assume it can't | **Measure it**: normalize (D-21) then `arcoreimg eval-img` ≥ 75. Ten minutes of this made attempt #1's entire matcher unnecessary |
| Show `model_viewer_plus` (WebView) and call it AR | Tracker `ARNode` + GLB in-session; WebView only on a non-camera Galería 3D |
| Import the AR plugin from a screen | Import it only in `lib/ar/trackers/` |
| Add detection booleans to a widget | Extend the sealed `ArSessionState` |
| Fall back to demo mode when the real session fails | Emit `ArFailed` with Spanish copy + a route to the manual path |
| Hardcode a single team for demo detection | Cycle all registered markers; always show the `MODO DEMO` badge |
| `isDebuggable = false`, `compileSdk` bumps, manual `com.google.ar:core`, JDK auto-download | Nothing — these need a constitution amendment (Article VI.8) |
| Prove detection with a test that loads an asset and matches it against itself | Fill in the device acceptance table, both control rows included |

If ARCore image tracking cannot pass acceptance, the **only** sanctioned
fallback is `HybridMarkerTracker` (D-19). Do not invent a third approach —
that is exactly how attempt #1 spiralled.

### Layering check before you finish

```bash
rg -l "ar_flutter_plugin" lib/ | rg -v "^lib/ar/trackers/"   # must print nothing
```

---

## What not to do

- Do not add Unity, a backend API, Firebase auth, or logins.
- Do not add Zona Norte / soccer Mundial branding as product theme.
- Do not ship forbidden filters.
- Do not treat the AR timer mock as production recognition.
- Do not commit secrets or huge media binaries without asking.
- Do not redesign away from `AppColors` / Poppins without amending Article IX.
- Do not hand-roll image recognition. See the AR don'ts table above.
- Do not delete or soften `docs/ar-postmortem.md`.
- Do not commit build output (`build/`, `.dart_tool/`, `android/.gradle/`).
