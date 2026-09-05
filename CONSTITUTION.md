# LMB Plusur Constitution

This file is the **source of truth for project governance**. Agents MUST read it
before writing specs, plans, or code. If a change conflicts with an article,
stop and resolve the conflict in a spec — do not silently override this document.

Human-facing product overview lives in `README.md` (to be expanded). Agent
operating rules live in `AGENTS.md`. The ordered backlog lives in
`WORK_ITEMS.md`.

**Version**: 1.1.1 | **Ratified**: 2026-09-04 | **Last Amended**: 2026-09-04

---

## Preamble — What LMB Plusur is

**LMB Plusur** is a Flutter mobile app for fans of the **Liga Mexicana de
Béisbol (LMB) — Zona Sur only**. It is a **degree / scholar project** that must
also behave like a real product: coherent baseball narrative, polished UI, and
a complete AR experience.

A user can **scan image markers / logos** to unlock AR experiences (3D stadiums,
trophies, balls, or historical players with animations and in-AR controls), or
**skip scanning** and find a team by name for non-marker content. The app also
ships a **baseball video archive** where each video can be previewed with
allowed visual filters, plus trivia and simulated live stats.

The product language of the UI and domain is **Spanish**. Engineering docs for
agents (`CONSTITUTION.md`, `AGENTS.md`, `WORK_ITEMS.md`) are written in
**English**.

| Layer | Technology | Location | Maturity |
|---|---|---|---|
| App shell | Flutter 3 / Dart 3.3+ | `lib/` | Implemented (navigation, theme, screens). |
| Team content | Local JSON | `assets/data.json` | Implemented for 10 Zona Sur clubs (historia + trivias). |
| AR | **Flutter-native (D-01 A)** | `lib/screens/ar_view_screen.dart` | Simulated detection only today. |
| Video filters | Flutter on-device | — | Not started; graded requirement. |
| Highlights / videos | Remote URLs (D-07) | demo data today | Placeholders until URLs are filled. |

This constitution is **Flutter-first**. The Dart app owns navigation, content,
camera UX, filters, and feature composition. Native ARKit/ARCore (or equivalent
plugins) are an **embedded capability**, not a parallel product. **Unity is out.**

### Theme note (professor handout vs product)

**Confirmed 2026-09-04:** the course started as a Mundial 2026 (soccer) brief;
the professor switched the assigned theme to **baseball / LMB** and left some
“Mundial 2026” strings in the handout and checklist by mistake.

**This product’s theme is LMB baseball (Zona Sur) only.** Agents MUST keep
visual and narrative coherence with baseball. Meet the handout’s *technical*
bars (filters, AR interactions, effects, packaging) using baseball content.
Do **not** add soccer/World Cup branding, assets, or copy to “match” leftover
Mundial wording.

---

## Core Principles

### I. Zona Sur only

The app MUST cover **only LMB Zona Sur** teams. Do not add Zona Norte clubs,
MLB clubs, soccer/World Cup clubs, or generic non-baseball content unless a
ratified amendment expands scope.

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
| Domain / content contract (`Equipo`, JSON shape, routes) | Spec **and** update to this constitution or data schema notes in the same change. |
| AR stack, filters, or persistence model | Spec that cites the articles / decisions it amends. Then update this constitution. |

Do not mix multiple work items in one change. Do not "while we're here" extras.

### III. Two entry paths, shared content, AR gated by scan

There are exactly **two ways** into team content:

1. **Scan marker (AR path)** — camera recognizes an image/logo marker → resolves
   to content (team and/or AR object) → opens the **AR window** with 3D model,
   interactive buttons, and AR modes.
2. **Select / search team (manual path)** — user browses or filters Zona Sur
   teams by name → **Team menu** for historia, trivia, video archive, simulated
   stats — **without** requiring a scan.

**Ratified (D-11):** Full marker-anchored AR (3D on image target + in-AR
action buttons) requires a successful scan. From the manual team menu the user
MAY tap **“Abrir experiencia AR”**, which launches the scanner (optionally
hinting which logo to point at). Do not fake a full AR session on the manual
path without camera recognition, except a clearly labeled **demo/fallback**
mode for development or devices without tracking.

Both paths MUST reuse the same visual system and, where features overlap, the
same data (`Equipo`, trivia, video catalog).

**Search (D-10):** Team list MUST include a simple name filter/search field
(client-side). No separate search microservice.

### IV. Spanish domain, English engineering

The **product domain is Spanish**:

- Models and JSON: `equipo`, `nombre`, `historia`, `fundacion`, `trivias`,
  `pregunta`, `opciones`, `respuestaCorrecta`, and future keys for AR assets /
  videos in Spanish where user-facing.
- User-facing copy: Spanish.
- Routes / screen names in Dart MAY stay English (`ArViewScreen`,
  `TeamMenuScreen`) to match Flutter conventions already in the repo.

Do not introduce a parallel English domain vocabulary for persisted or JSON
fields. Agent docs stay in English.

### V. Content is data-driven and local-first

Team facts, trivia, AR asset refs, and video catalog entries live in **local
data**, not hardcoded widget trees.

- Primary store: `assets/data.json` (and related local JSON/assets as needed)
  loaded via `DataService` (or successors).
- **No application API / backend (D-06).** Agents MUST NOT invent REST/GraphQL
  clients, auth servers, or CMS sync.
- **Media MAY use remote URLs (D-07)** for videos/highlights. Metadata stays
  local; playback may need network.
- Screens MUST receive models (or ids resolved to models), not copy-pasted
  team strings.
- Adding a team means extending data + assets, not cloning screens per club.

### VI. Flutter-native AR behind a clear boundary (D-01)

**Ratified engine: Flutter-native** (camera + on-device image/marker recognition
+ 3D GLB/model viewing via ARCore/ARKit-capable Flutter plugins or equivalent).
Do **not** enable `flutter_unity_widget` or add a Unity project.

Contract:

- Flutter owns routing, overlays, permissions UX, buttons, dialogs, audio cues,
  trivia/stats UI, and video filters.
- AR session: **start → detect marker id → load keyed 3D asset → user interacts
  via Flutter controls → modes / exit**.
- Simulated AR is allowed only as **dev/demo** until real tracking works; label
  it when shown as fake detection.
- 3D assets MUST be keyed to stable ids (team and/or `marcador` / object id).
- Do not bury historia text, trivia scoring, or filter logic inside native
  opaque code when it can live in Dart/data.

**Minimum academic AR bar (see Grading checklist):**

- ≥ **3 distinct scannable markers**, each with **specific** content.
- In the AR window: interactive buttons with ≥ **2 action types** (e.g. play
  animation, show info + TTS/narration, play video, show simulated stats,
  particles/VFX).
- Multiple interaction modes (e.g. galería AR, trivia AR, videos inmersivos).
- AR chrome MUST match main app style (colors, type, icons, layout language).

**3D content (D-03):** Prefer baseball-coherent models — estadios, trofeos,
pelotas, jugadores históricos — authored by the student (or AI-assisted).
Animations: celebrate, gestures, idle loops, 360° turn on “Información”, etc.

### VII. Video archive and filters (D-05) — not still-photo grading

The **graded media feature is video + filters**, per professor specs (not a
separate still-photo camera product).

- Provide an UI section with a **catalog of baseball-themed videos** (remote
  URLs). Each video MUST be editable/previewable with filters.
- **Allowed filter families (MUST implement representatives of each):**
  - Desenfoque (blur)
  - Pixelado
  - Cámara térmica
  - Ajuste de color
  - Personalizados: e.g. suavizado, colores pasteles, alta saturación
- **Forbidden filters (MUST NOT ship):**
  - Blanco y negro
  - Escala de grises
  - Sepia
  - Exposición
  - Colores invertidos
- Filters run **on-device** on the playback/preview pipeline. Do not upload
  user media to a server.
- Still-image capture is **out of MVP scope** unless a later work item adds it;
  do not confuse it with the required video-filter feature.
- Never commit large binary user exports or secrets.

### VIII. No accounts; light local memory (D-08)

- **No logins, profiles, or cloud accounts.**
- Trivia MAY persist **only the last score** for that team/session on device
  (e.g. shared preferences). No leaderboards backend.
- Simulated “tiempo real” stats are **local mock streams/timers**, not live
  league APIs.

### IX. Visual system + feedback

Shipping UI follows the existing dark LMB Plusur look:

- Colors: `AppColors` (`lib/theme/app_colors.dart`).
- Typography: Poppins via `google_fonts`.
- Shared chrome: `AppHeader`, `ScreenBackground`, `FeatureCard`,
  `PrimaryButton`, `AppLogo`.

AR overlays and the video-filter UI MUST reuse the same language.

**Feedback (professor):** actions MUST give visual and/or short audio feedback
(button state changes, short sounds, snackbars/toasts). Do not leave critical
actions silent.

### X. Small surface, explicit architecture

```
lib/
  app.dart, main.dart
  routes/          named routes only
  screens/         one primary screen per route
  widgets/         reusable UI
  models/          Equipo, Trivia, ArMarcador, VideoItem, …
  services/        DataService, ArSession facade, FilterEngine, …
  data/            demo / mock helpers
  theme/           colors, theme, assets keys
assets/            data.json, images, markers, 3D models, SFX
```

- Navigation via `AppRoutes` + `onGenerateRoute`.
- I/O in `services/`, not inside `build()`.
- Prefer facades so UI does not hard-code a specific AR plugin API.

### XI. Platforms and packaging (D-02, D-09)

- **Ship for both Android and iOS** in principle; **primary testing is Android
  (APK)**.
- Keep iOS project healthy enough that IPA build remains plausible.
- No hard course deadline yet — definition of “enough” tracks the **Grading
  checklist** below until the human freezes MVP.

---

## Canonical product surface

### Actors

| Actor | Can |
|---|---|
| Fan (unauthenticated) | Scan markers; select/search teams; use AR modes; historia; trivia; video archive + filters; see simulated stats; hear/see action feedback. |
| Developer / demo mode | Use labeled simulated detection when tracking is unavailable. |

### Happy paths

```
Splash → Main
  ├─ Escanear → detect marcador (≥3 distinct) → AR window
  │       ├─ modo Galería AR / Trivia AR / Video inmersivo
  │       ├─ botones: animación | información+TTS | video | stats | VFX
  │       └→ shared features (historia, trivia, videos)
  └─ Seleccionar equipo → búsqueda por nombre → Team menu
          ├─ Historia | Trivia (last score) | Videos+filtros | Stats simuladas
          └─ Abrir experiencia AR → scanner (same AR stack)
```

### Feature contracts

| Feature | Status | Contract |
|---|---|---|
| Historia | Implemented | `equipo.historia` + fundación. |
| Trivia / retos | Implemented (extend) | From `trivias`; last score only; AR trivia mode planned. |
| Video archive + filters | Planned | Remote URL catalog; allowed filters only. |
| AR markers (≥3) | Planned / mocked | Distinct content per marker. |
| AR controls | Planned | ≥2 action types; style-matched overlay. |
| Simulated live stats | Planned | Local mock “tiempo real”. |
| Multiple AR modes | Planned | e.g. galería, trivia AR, video inmersivo. |
| Team search | Partial → required | Client-side name filter on team list. |
| User feedback | Partial | Sounds + visual state + short messages. |

### Failure modes agents MUST handle

- Camera / mic permission denied → Spanish copy + manual team path.
- Marker not recognized → retry; never crash; offer manual select.
- Missing 3D asset → graceful fallback, not a red screen.
- Remote video URL fails → placeholder + message; app stays stable.
- Low-end device → prefer lighter models/effects; avoid unbounded particle spam.

---

## Academic grading checklist (definition of done)

Agents MUST treat these as release gates for the scholar deliverable:

| Pts | Gate |
|---|---|
| 10 | AR experience with **≥3 distinct scannable elements**, each with specific content. |
| 10 | Interactive buttons with **≥2 action types** (e.g. video, stats, animation). |
| 15 | 3D animations/effects coherent with **baseball** theme (ignore leftover “Mundial 2026” rubric text — see Theme note). |
| 10 | Packaged app (**APK** required for testing; IPA if feasible). |
| 10 | Final UI matches agreed baseball / LMB Plusur visual theme. |
| 10 | Extra / bonus mode (trivia, AR minigame, or immersive gallery). |
| 15 | Mobile performance (load time, stability). |
| 10 | Explanatory video showing full AR usage (human deliverable; agents support polish). |

---

## Stack constraints

MUST:

- Flutter/Dart application shell; **Flutter-native AR (no Unity)**.
- Keep `sdk: ">=3.3.0 <4.0.0"` unless a ratified upgrade says otherwise.
- Local metadata; remote URLs only for media.
- Key markers/assets by stable ids.
- Implement only **allowed** video filters; never ship forbidden ones.
- Keep `flutter analyze` clean on touched files when practical.

SHOULD:

- Facades: `ArSession`, `FilterEngine`, `StatsSimulator`, `FeedbackService`.
- Asset layout: `assets/markers/`, `assets/models/<id>/`, `assets/sfx/`.
- Optimize 3D (compressed GLB, limited simultaneous effects).

MAY:

- TTS for “Información” narration.
- SharedPreferences for last trivia score.
- Widget/unit tests for filters, trivia scoring, JSON parsing.

MUST NOT:

- Add Unity, a backend API, or login/auth.
- Expand beyond Zona Sur baseball without amendment.
- Ship forbidden filters.
- Commit secrets or huge raw capture dumps.
- Treat the AR timer mock as production recognition.

---

## Known debt (do not "fix" casually)

1. **AR is simulated** — real marker tracking + 3D unfinished.
2. **Logos/markers not collected yet (D-04)** — need ≥3 printable targets.
3. **Video filter UI missing.**
4. **Highlights/videos still demo** — swap to real remote URLs.
5. **Minimal automated tests.**
6. **README still Flutter template.**
7. **`flutter_unity_widget` comment** — leave unused; do not activate.

Track fixes via `WORK_ITEMS.md`.

---

## Decisions log

| ID | Decision | Status |
|---|---|---|
| D-01 | AR engine = **Flutter-native (A)**. Unity rejected. | **Ratified 2026-09-04** |
| D-02 | **Android + iOS**; primary testing **Android**. | **Ratified 2026-09-04** |
| D-03 | 3D = estadios / trofeos / pelotas / jugadores históricos; student- or AI-authored; interactive animations. | **Ratified 2026-09-04** |
| D-04 | Scholar use OK for marks; logos **not yet collected** — blocking real scan QA until ≥3 markers exist. | **Ratified 2026-09-04** |
| D-05 | Graded feature = **video catalog + filters** (allowed/forbidden lists). Still photos out of MVP. | **Ratified 2026-09-04** |
| D-06 | **No API**; local JSON + assets; media via URLs only. | **Ratified 2026-09-04** |
| D-07 | Videos/highlights = **remote URLs**. | **Ratified 2026-09-04** |
| D-08 | **No logins**; optional **last trivia score** on device only. | **Ratified 2026-09-04** |
| D-09 | No hard deadline; ship against **grading checklist** until human says enough. | **Ratified 2026-09-04** |
| D-10 | Team list includes **client-side name search/filter**. | **Ratified 2026-09-04** |
| D-11 | Marker AR requires scan; manual path uses **Abrir experiencia AR** → scanner. | **Ratified 2026-09-04** |

Open residual (non-blocking for backlog writing):

| ID | Notes |
|---|---|
| R-01 | Exact plugin choice for image tracking + 3D (evaluate in US-AR spike). |
| R-02 | Which 3 of 10 teams (or objects) are the first scannable markers. |
| R-03 | Final remote video URL list (baseball-themed). |

---

## Governance

1. **This file wins.** `AGENTS.md` tells agents how to work. `WORK_ITEMS.md`
   holds executable prompts. `README.md` tells humans how to run the app.
2. **Amendments** require rationale, article touched, and version bump (patch /
   minor / major). Update **Last Amended**.
3. **Code that violates an article** is allowed only as documented known debt
   being fixed by the active work item.
4. **Ambiguity:** ask the human — especially marker art, video URLs, and
   model sourcing. Do not re-open Mundial branding; theme is baseball.
5. **Review gate:** change is not done until constitution/data/routes still
   match, grading gates are not regressed, and forbidden filters were not added.
