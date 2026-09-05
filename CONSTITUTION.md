# LMB Plusur Constitution

This file is the **source of truth for project governance**. Agents MUST read it
before writing specs, plans, or code. If a change conflicts with an article,
stop and resolve the conflict in a spec — do not silently override this document.

Human-facing product overview lives in `README.md` (to be expanded). Agent
operating rules live in `AGENTS.md`. The ordered backlog will live in
`WORK_ITEMS.md` once open decisions below are ratified.

**Version**: 1.0.0 | **Ratified**: 2026-09-04 | **Last Amended**: 2026-09-04

---

## Preamble — What LMB Plusur is

**LMB Plusur** is a Flutter mobile app for fans of the **Liga Mexicana de
Béisbol (LMB) — Zona Sur only**. A user can scan a team logo to unlock an AR
experience (team-specific 3D model + animation) and team features, or skip the
scan and find the team by name. After interacting with a team, the user can
take photos and apply in-app filters.

The product language of the UI and domain is **Spanish**. Engineering docs for
agents (`CONSTITUTION.md`, `AGENTS.md`) are written in **English**.

| Layer | Technology | Location | Maturity |
|---|---|---|---|
| App shell | Flutter 3 / Dart 3.3+ | `lib/` | Implemented (navigation, theme, screens). |
| Team content | Local JSON | `assets/data.json` | Implemented for 10 Zona Sur clubs (historia + trivias). |
| AR | **Not ratified** (see D-01) | `lib/screens/ar_view_screen.dart` | Simulated detection only; Unity widget commented in `pubspec.yaml`. |
| Photos / filters | **Not started** | — | Required product feature; no screen yet. |
| Highlights | `video_player` + demo data | `lib/screens/highlights_screen.dart` | Placeholder / demo paths. |

This constitution is **Flutter-first**. The Dart app owns navigation, content,
camera UX, and feature composition. Any native/Unity AR module is an **embedded
capability**, not a parallel product.

---

## Core Principles

### I. Zona Sur only

The app MUST cover **only LMB Zona Sur** teams. Do not add Zona Norte clubs,
MLB clubs, or generic baseball content unless a ratified amendment expands
scope.

**Canonical team ids** (source: `assets/data.json`):

| `id` | Nombre |
|---|---|
| `diablos_rojos` | Diablos Rojos del México |
| `bravos_leon` | Bravos de León |
| `conspiradores_queretaro` | Conspiradores de Querétaro |
| `aguila_veracruz` | El Águila de Veracruz |
| `guerreros_oaxaca` | Guerreros de Oaxaca |
| `leones_yucatan` | Leones de Yucatán |
| `olmecas_tabasco` | Olmecas de Tabasco |
| `pericos_puebla` | Pericos de Puebla |
| `piratas_campeche` | Piratas de Campeche |
| `tigres_quintana_roo` | Tigres de Quintana Roo |

Team identity in code MUST use these stable `id` values. Display names MAY be
uppercased in UI (`displayName`) but MUST NOT invent a second id scheme.

### II. Spec-anchored change

LMB Plusur is developed **spec-first**. Agents MUST NOT implement a behavior
change from a vague prompt.

| Change type | Required artifact before code |
|---|---|
| Item from `WORK_ITEMS.md` | The item's Prompt block **is** the spec. Follow it as written. |
| New feature not in the backlog | A short spec: context, actors, flow, acceptance criteria, files, out of scope. |
| Domain / content contract (`Equipo`, JSON shape, routes) | Spec **and** update to this constitution or `assets/data.json` schema notes in the same change. |
| AR stack, camera, or persistence model | Spec that cites the articles / decisions it amends. Then update this constitution. |

Do not mix multiple work items in one change. Do not "while we're here" extras.

### III. Two entry paths, one team context

There are exactly **two ways** to reach a team's feature menu:

1. **Scan logo (AR path)** — camera / image-target flow detects a logo → resolves
   to an `Equipo` → shows the team AR experience (3D model + animation) and the
   same feature set as the manual path.
2. **Select / search team (manual path)** — user browses or searches Zona Sur
   teams by name → same feature menu **without** requiring a successful scan.

Both paths MUST land on the same team-scoped feature surface (historia, trivia,
highlights, and later photo/filters as ratified). Do not fork divergent menus
per entry path. The AR 3D experience MAY be unavailable or stubbed on the
manual path until D-01 / D-03 say otherwise — but content features stay shared.

### IV. Spanish domain, English engineering

The **product domain is Spanish**:

- Models and JSON: `equipo`, `nombre`, `historia`, `fundacion`, `trivias`,
  `pregunta`, `opciones`, `respuestaCorrecta`.
- User-facing copy: Spanish.
- Routes / screen names in Dart MAY stay English (`ArViewScreen`,
  `TeamMenuScreen`) to match Flutter conventions already in the repo.

Do not introduce a parallel English domain vocabulary for persisted or JSON
fields (`team` / `history` / `foundationYear` as JSON keys). Agent docs stay in
English; product terms stay Spanish when referring to domain data.

### V. Content is data-driven

Team facts, trivia, and (when added) media references live in **data**, not
hardcoded widget trees.

- Primary store today: `assets/data.json` loaded via `DataService`.
- Screens MUST receive an `Equipo` (or id resolved to `Equipo`), not copy-pasted
  team strings.
- Adding a team means extending the data file (and any required assets), not
  cloning a screen per club.
- Trivia selection (currently "5 random" in UI copy) MUST remain driven by the
  team's `trivias` list.

When a backend is introduced (D-06), the local JSON shape remains the **client
contract** until a migration spec says otherwise.

### VI. AR is a capability behind a clear boundary

Regardless of the ratified AR engine (D-01):

- Flutter owns routing, overlays, permissions UX, and post-detect navigation.
- The AR module exposes a small, documented contract: **start session → detect
  team id (or fail) → present / play team 3D asset → hand control back to
  Flutter features**.
- Simulated AR (`ArViewScreen` timer mock) is allowed only as a **dev stand-in**
  until the real detector lands. Do not ship fake detection as if it were real
  recognition without labeling it as demo/mock in UI when appropriate.
- One 3D experience per team id. Assets MUST be keyed by the same `id` as
  `assets/data.json`.
- Do not embed business content (full historia text, trivia logic) inside the
  AR engine — keep that in Flutter/data.

### VII. Camera, photos, and filters respect the user

- Request camera (and gallery, if needed) permissions with clear Spanish copy
  explaining why.
- Photo capture and filters are an **in-app feature**, not a silent background
  capture.
- Filters apply to photos the user took (or explicitly imported, if that option
  is ratified). Do not apply filters by mutating unrelated screenshots without
  user action.
- Do not upload photos to a remote server unless D-06 / a privacy spec allow it.
  Default assumption for v1: **on-device only**.
- Never commit real user photos into the repo.

### VIII. Offline-capable MVP, no invented backend

Until D-06 is ratified:

- The app MUST run with bundled assets and local data.
- Agents MUST NOT invent API clients, auth, or cloud sync "for completeness".
- Network use is limited to explicitly intended media (e.g. remote highlight
  URLs already present in demo data) and package CDN fonts if already used.

### IX. Visual system consistency

Shipping UI follows the existing dark LMB Plusur look:

- Colors: `AppColors` in `lib/theme/app_colors.dart` (navy base, light
  buttons, muted text).
- Typography: Poppins via `google_fonts` as already used.
- Shared chrome: `AppHeader`, `ScreenBackground`, `FeatureCard`, `PrimaryButton`,
  `AppLogo`.

New screens MUST reuse these primitives. Do not introduce a second design
language (Material 3 defaults, random accent purple, card-heavy dashboards)
without amending this article.

### X. Small surface, explicit architecture

Prefer the current layout:

```
lib/
  app.dart, main.dart
  routes/          named routes only
  screens/         one primary screen per route
  widgets/         reusable UI
  models/          Equipo, Trivia, …
  services/        DataService and future camera/AR facades
  data/            demo / mock helpers
  theme/           colors, theme, assets keys
assets/            data.json, images, future 3D/filter assets
```

- Navigation goes through `AppRoutes` + `onGenerateRoute`. Do not add a second
  router package without a ratified decision.
- Put I/O and parsing in `services/`, not in `build()` methods.
- Keep widgets dumb; pass `Equipo` in. Do not re-fetch JSON inside every leaf
  widget when the parent already has the model.

---

## Canonical product surface

### Actors

| Actor | Can |
|---|---|
| Fan (unauthenticated) | Scan logo or select team; view historia; play trivia; watch highlights; take photos and apply filters (once built). |
| Developer / demo mode | Use simulated AR detection when real tracking is unavailable. |

No roles, accounts, or admin panel in v1 unless D-08 is ratified.

### Happy paths

```
Splash → Main
  ├─ Escanear Logo → AR session → detect equipo → AR 3D + feature overlay
  │                                            └→ Historia | Trivia | Highlights | (Fotos)
  └─ Seleccionar Equipo → lista / búsqueda → Team menu
                                           └→ Historia | Trivia | Highlights | (Fotos)
```

### Feature contracts (current + planned)

| Feature | Status | Contract |
|---|---|---|
| Historia | Implemented | Show `equipo.historia` (and foundation year). |
| Trivia | Implemented | Draw from `equipo.trivias`; score → results screen. |
| Highlights | Partial | Play team-related clips; demo data allowed until real media is supplied. |
| AR 3D on logo | Planned / mocked | After detect, show team-keyed animated 3D model. |
| Photo + filters | Planned | Capture → choose filter → preview → save/share per D-05. |
| Team search | Partial | Manual list exists; dedicated search UX may be added without changing ids. |

### Failure modes agents MUST handle

- Camera permission denied → Spanish explanation + path to manual team select.
- Logo not recognized → retry UX; never crash; offer manual select.
- Missing 3D asset for a team → graceful fallback (2D logo / message), not a red
  screen.
- Missing highlight media → placeholder already used by the app; keep that
  pattern.

---

## Stack constraints

MUST:

- Stay on Flutter/Dart for the application shell.
- Keep `sdk: ">=3.3.0 <4.0.0"` unless a ratified upgrade bump says otherwise.
- Keep analysis via `flutter_lints` clean for touched files.
- Key team assets by `Equipo.id`.
- Gate AR engine choice on **D-01** before adding heavy native modules.

SHOULD:

- Prefer facades (`ArSession`, `PhotoCaptureService`, `FilterEngine`) so the UI
  does not depend on Unity vs native AR details.
- Keep `flutter_unity_widget` commented / unused until D-01 chooses Unity.
- Colocate team media under predictable asset paths
  (e.g. `assets/teams/<id>/...`) when assets are added.

MAY:

- Use platform channels or an embedded engine **only** behind the AR facade.
- Add unit/widget tests for data parsing, trivia scoring, and filter pipelines.

MUST NOT:

- Expand to Zona Norte or non-LMB leagues without amending Article I.
- Commit secrets, API keys for AR cloud services, or user photos.
- Treat the current simulated AR timer as production recognition.
- Add Firebase / auth / payments unless a ratified decision opens that door.

---

## Known debt (do not "fix" casually)

These are acknowledged gaps, not invitations to freelance:

1. **AR is simulated** — `ArViewScreen` hardcodes a delayed "detection" of
   Guerreros (or first team). Real image targets + 3D are unfinished.
2. **Unity dependency is commented** — `flutter_unity_widget` is not active;
   stack choice is **D-01**.
3. **Photos / filters do not exist** yet — required product scope, no
   `WORK_ITEMS` until D-05 answers land.
4. **Highlights use demo / placeholder media** — not final broadcast content.
5. **No automated test coverage** of domain logic beyond the default widget
   smoke test.
6. **README** is still the Flutter template — not yet the human product brief.

When `WORK_ITEMS.md` exists, new defects and stories go there in the standard
prompt format instead of drive-by patches.

---

## Open decisions (blocked until a human ratifies)

Agents MUST NOT silently pick these during implementation:

| ID | Decision | Options / notes |
|---|---|---|
| **D-01** | AR engine | **A)** Flutter-native (camera + on-device logo matching + GLB/SceneView or ARCore/ARKit plugin). **B)** Unity (AR Foundation / Vuforia) embedded via `flutter_unity_widget`. **Recommendation for AI-driven development: A** — see agent-facing note in `AGENTS.md`. |
| **D-02** | Target platforms | Android only / iOS only / both. Affects AR plugin choice and min OS. |
| **D-03** | 3D content design | Per-team mascot? Stadium? Player? Animation style? Who supplies GLB/FBX assets? |
| **D-04** | Logo targets & rights | Who provides printable/official logos? Image-target authoring pipeline? Licensing constraints for LMB marks? |
| **D-05** | Photo & filters scope | Capture-only vs import; filter list; save to gallery; share sheet; AR snapshot vs separate camera mode. |
| **D-06** | Persistence / backend | Bundled JSON forever vs CMS/API for historias, trivias, highlights. |
| **D-07** | Highlights media source | Local assets vs remote URLs; copyright / league media rights. |
| **D-08** | Accounts | None (v1 default) vs optional profiles / saved scores. |
| **D-09** | MVP freeze date / academic constraints | What MUST ship for the first deliverable vs later. |

When a decision is ratified, amend the matching article **in the same change**
and remove or mark the row ratified in this table.

---

## Governance

1. **This file wins.** `AGENTS.md` tells agents how to work. `README.md` tells
   humans how to run the app. If they disagree with this constitution, update
   this file first.
2. **Amendments** require: a short rationale, the article being changed, and a
   version bump (patch for clarifications, minor for a new article, major if a
   principle is reversed). Update **Last Amended**.
3. **Code that violates an article** is allowed only when it is documented under
   *Known debt* and the change in progress is the fix.
4. **Ambiguity:** ask the human. Do not invent league scope, AR stack, or photo
   upload policy.
5. **Review gate:** a change is not done until routes/models/assets still match
   the constitution, no new team id scheme was introduced, and open decisions
   were not silently closed by the agent.
