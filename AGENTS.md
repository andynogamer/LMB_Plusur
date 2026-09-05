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
| `CONSTITUTION.md` | Non-negotiable principles + decisions log (v1.1.0). |
| `AGENTS.md` | This file. |
| `WORK_ITEMS.md` | Backlog as copy-paste agent prompts. |
| `lib/` | Flutter app. |
| `assets/data.json` | Canonical team content (10 clubs). |
| `assets/` | Images, future markers / models / sfx. |
| `pubspec.yaml` | Dependencies — do **not** enable Unity widget. |
| `test/` | Flutter tests (thin today). |
| `README.md` | Human run docs (still template). |

---

## Spec-anchored workflow

1. Read `CONSTITUTION.md` (especially Decisions log + grading checklist).
2. Take **one** item from `WORK_ITEMS.md`; the `Prompt` block is the spec.
3. Implement only that item. One item per branch / PR / commit.
4. Update constitution/data if the domain contract changes.
5. Do not mix bugfix + feature. Do not expand league scope.

If the request conflicts with the constitution, **stop and ask**.

---

## Current phase (post D-01…D-11)

- UI shell + local historia/trivia: present.
- AR: mock only → real Flutter-native marker tracking + 3D is the main gap.
- Video filters: not started (graded).
- Data: local JSON; videos via remote URLs; no backend.
- Markers/logos: not collected yet (R-02) — implement pipeline with placeholders.
- Primary device under test: **Android**.

Suggested order: follow the index in `WORK_ITEMS.md` (foundation → AR spike →
markers → AR UI → filters → bonus → polish/APK).

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
- Facades for AR, filters, feedback, simulated stats.
- Last trivia score only via local persistence — no accounts.
- `flutter analyze` on touched code when practical.
- **Forbidden video filters must never appear** (B&W, grayscale, sepia,
  exposure, invert). See Constitution Article VII.

---

## AR (ratified)

Flutter-native only. Image/marker recognition + GLB/3D + Flutter overlays.
≥3 distinct markers for grading. AR chrome matches main UI. Manual team path
opens scanner via **Abrir experiencia AR** — do not fake full marker AR.

R-01 resolved ? see `docs/ar-spike.md`. Embed ARView in US-06.

---

## What not to do

- Do not add Unity, a backend API, Firebase auth, or logins.
- Do not add Zona Norte / soccer Mundial branding as product theme.
- Do not ship forbidden filters.
- Do not treat the AR timer mock as production recognition.
- Do not commit secrets or huge media binaries without asking.
- Do not redesign away from `AppColors` / Poppins without amending Article IX.
