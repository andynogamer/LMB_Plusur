# AGENTS.md — LMB Plusur

Ambient rules for coding agents. Governance (what must never change without a
spec) is in [`CONSTITUTION.md`](./CONSTITUTION.md). **Read that file first.**

This repo is a **Flutter-first** mobile app. Stay in Dart/`lib/` unless the
active spec explicitly opens native Android/iOS or an embedded AR engine.

---

## What this repository is

LMB Plusur is an AR fan app for **LMB Zona Sur** baseball clubs. Users scan a
team logo (or pick the team manually), then explore historia, trivia, highlights,
and (planned) photo filters with a team-specific 3D AR moment.

| Path | What it is |
|---|---|
| `CONSTITUTION.md` | Non-negotiable product and architecture principles. |
| `AGENTS.md` | This file — how agents operate day to day. |
| `WORK_ITEMS.md` | Ordered backlog (bugs + user stories as copy-paste prompts). **Not created yet** — wait until open decisions D-01…D-09 are answered. |
| `lib/` | Flutter application code. |
| `assets/data.json` | Canonical team content (10 Zona Sur clubs). |
| `assets/images/` | Static images / placeholders. |
| `pubspec.yaml` | Dependencies. Unity widget is commented until D-01. |
| `test/` | Flutter tests (currently minimal). |
| `README.md` | Human run instructions (still template — improve when asked). |

---

## Spec-anchored workflow

1. Read `CONSTITUTION.md`.
2. Identify the spec:
   - Backlog item → use the `Prompt` block in `WORK_ITEMS.md` as the spec.
   - New work → write context, acceptance criteria, files, and out-of-scope **before** coding.
3. Implement only that spec. One work item per branch / PR / commit.
4. If you change domain JSON shape, routes, or team ids: update the constitution
   (and data) in the same change.
5. If you change a principle or ratify an open decision: amend `CONSTITUTION.md`
   (version bump + Last Amended).
6. Do not mix a bug fix with a feature. Do not expand Zona Sur scope casually.

If the request conflicts with the constitution, **stop and ask**.

---

## Current phase

- **UI shell:** splash, main, AR mock, team list, team menu, historia, trivia,
  trivia results, highlights — working with local data.
- **AR:** simulated detection only. Real logo tracking + 3D blocked on **D-01**.
- **Photos / filters:** not started; blocked on **D-05** (and related).
- **Backend:** none; keep offline-capable until **D-06**.
- **WORK_ITEMS.md:** deferred until the human answers the open decisions in the
  constitution.

Suggested next human step: answer D-01…D-09 (especially D-01 AR engine and
D-05 photo scope), then generate `WORK_ITEMS.md`.

---

## Language

- Agent docs: English.
- UI copy and JSON domain fields: **Spanish** (`equipo`, `historia`, `trivias`).
- Dart type/file names MAY stay English (`Equipo`, `ArViewScreen`) to match the
  existing codebase.
- Do not rename JSON keys to English.

---

## Engineering defaults

- Flutter Material app with named routes in `lib/routes/app_routes.dart`.
- Theme tokens live in `lib/theme/`. Reuse `AppColors`, headers, feature cards.
- Load teams through `DataService` / `Equipo.fromJson` — do not hardcode club
  lists in widgets.
- Prefer small facades for AR, camera, and filters so UI does not hard-depend
  on Unity vs Flutter-native plugins.
- Run `flutter analyze` on touched areas before calling work done when practical.
- Do not enable `flutter_unity_widget` until D-01 chooses Unity.

---

## AR stack note for agents (D-01)

**Default recommendation while D-01 is open: prefer Flutter-native (Option A).**

Why (especially for AI-assisted development):

- Agents edit Dart reliably; they struggle with Unity Editor, prefabs, `.meta`
  files, and export/build pipelines.
- Logo scan + one animated GLB per team + Flutter overlays matches the product
  without a second full game engine.
- Photo filters stay pure Flutter (`camera` / `image` / fragment shaders).
- Unity still wins if you need heavy VFX, complex multi-object scenes, or an
  existing Unity asset pipeline / teammate owned Unity project.

Until the human ratifies D-01, do not add Unity modules or delete the mock AR
path. You MAY sketch facades and asset folder conventions that work for either
option.

---

## What not to do

- Do not invent a backend, auth, or payments.
- Do not add Zona Norte or non-LMB teams.
- Do not treat the AR timer mock as real recognition in production UX.
- Do not commit secrets, cloud AR API keys, or user photos.
- Do not create `WORK_ITEMS.md` until the human asks or open decisions are
  answered enough to write honest acceptance criteria.
- Do not start a visual redesign that abandons `AppColors` / Poppins without an
  amendment to Constitution Article IX.
