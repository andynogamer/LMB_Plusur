# Agent handoff — start here

**This file is the session entry point.** A new agent reads this first, works
one item, then **updates this file before finishing** (§6 — mandatory).

**Last updated:** 2026-09-07 · by: AR-01 session

---

## 1. What this project is

Flutter 3.47 / Dart 3.13 mobile app. AR fan app for **LMB Zona Sur** (10 Mexican
baseball clubs). A scholar project that must also behave like a real product.

Repo: `C:\Users\T450SCMPTRC\Desktop\LMB_Plusur` — branch **`fresh-start`**.

## 2. Read before writing any code

These are **binding**, not advisory:

| # | File | What it gives you |
|---|---|---|
| 1 | `CONSTITUTION.md` | Governance, v2.2.0, decisions D-01…D-21 |
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
- AR-01 — `Marcador` + `MarkerRegistry`. `assets/ar_markers.json` loads the
  three active D-20 markers through `DataService.cargarMarcadores()`.
  `resolve` is an exact map lookup keyed by `Marcador.id`. The spare
  (`marcador_pelota_bravos`) is **not** in that JSON — printable only.
  `anchoMetros` is **0.15** (the planned 15 cm print), not a measured width;
  do not treat it as real until the human records the print (gates AR-05).
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

- Print the 4 markers at ≥ 15 cm on **matte** paper, measure width in metres →
  becomes `anchoMetros` (JSON currently holds the planned 0.15, not a
  measurement). Gates **AR-05** only.

**Next**

```
AR-02 → AR-03      no plugin, no camera, fully unit-testable
AR-04 → AR-05 → AR-06 → AR-07   native AR
```

Do **not** start AR-04 until AR-02 and AR-03 are merged and green. That ordering
is the whole point of the reset: prove the state machine before native risk
enters.

`lib/ar/` has `marker_registry.dart` only. `lib/screens/ar_view_screen.dart` is
still the pre-reset `Timer` mock — it gets **deleted** in AR-03, not patched.

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
- `arcoreimg` lives at `tools/bin/arcoreimg.exe` (git-ignored; re-download from
  the ARCore SDK if missing — see marker guide §4). Score markers with:
  ```powershell
  $env:ARCOREIMG = "$PWD\tools\bin\arcoreimg.exe"
  powershell -ExecutionPolicy Bypass -File tools/score_markers.ps1
  ```
- Never commit `build/`, `.dart_tool/`, `android/.gradle/`, `tools/bin/`.
- `flutter pub get` dirties `windows/flutter/generated_*` with line-ending-only
  noise. Restore with `git checkout -- windows/`.

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
| 2026-09-07 | **AR-01.** `Marcador` / `TipoMarcador`, `assets/ar_markers.json` (3 active D-20 markers, spare omitted), `DataService.cargarMarcadores()`, `MarkerRegistry.resolve` exact lookup. Tests: 3 passed (`marker_registry_test.dart`). `anchoMetros` left at 0.15 — planned print, not measured. |
| 2026-09-07 | **AR-00 code half** (commit `cd82136`). Measured all 10 logos with `arcoreimg`. 4 pass ≥ 75 after normalization; shipped to `assets/markers/`, wired into `pubspec.yaml`. Added `tools/normalize_markers.ps1` + `tools/score_markers.ps1`. **Amended D-20** (the 3 originally ratified markers scored 50/50/none — picked unmeasured) and added **D-21** (normalize + re-score). Constitution → v2.1.0. |
| 2026-09-07 | **AR reset governance.** Attempt #1 abandoned. Wrote `ar-postmortem.md`, `ar-architecture.md`, `ar-marker-guide.md`; rewrote Article VI into 11 enforceable clauses; ratified D-12…D-20; split monolithic US-05…US-08 into slices AR-00…AR-07. Constitution → v2.0.0. Added `.cursor/rules/`. |
| 2026-09-06 | US-01…US-04 delivered (commit `69aa1ff`). |

## 8. How to work

Pick **one** item from `WORK_ITEMS.md`, follow its `Prompt` block literally,
satisfy its `Criterios de aceptación`, run `flutter analyze` on touched files,
do the §6 documentation pass, then stop and report.

If a request conflicts with the constitution, or repeats a postmortem root cause
(RC-1…RC-7), **say which one it repeats and stop** instead of complying.

## 9. Current task

> Implement **AR-02** (`ArTracker` seam + session state machine — no plugin).
> Read its `Prompt` block in `WORK_ITEMS.md` and follow it exactly.

_(The human edits this line each session. Leave it pointing at the next item
when you finish.)_
