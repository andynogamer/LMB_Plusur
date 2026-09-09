# LMB Plusur Constitution

This file is the **source of truth for project governance**. Agents MUST read it
before writing specs, plans, or code. If a change conflicts with an article,
stop and resolve the conflict in a spec — do not silently override this document.

Human-facing product overview lives in `README.md` (to be expanded). Agent
operating rules live in `AGENTS.md`. The ordered backlog lives in
`WORK_ITEMS.md`.

**Binding technical annexes** (normative, referenced by Article VI):

| Document | Purpose |
|---|---|
| [`docs/agent-handoff.md`](./docs/agent-handoff.md) | **Session entry point.** Current state, next item, environment gotchas. Read first, update last (Governance §8). |
| [`docs/ar-postmortem.md`](./docs/ar-postmortem.md) | Why AR attempt #1 failed. Every Article VI rule traces to a root cause here. **Read before touching AR.** |
| [`docs/ar-architecture.md`](./docs/ar-architecture.md) | The AR technical contract: layers, `ArTracker` seam, state machine, error taxonomy, budgets. |
| [`docs/ar-marker-guide.md`](./docs/ar-marker-guide.md) | How to author printable markers ARCore can actually track. |

**Version**: 2.4.4 | **Ratified**: 2026-09-04 | **Last Amended**: 2026-09-08

> **v2.0.0 — AR reset.** AR attempt #1 (branch `ar-have-too-many-errors`) was
> abandoned and work restarted on `fresh-start`. Article VI was rewritten from
> a one-line engine choice into an enforceable architecture, and decisions
> **D-12 … D-20** were ratified. Residuals **R-01** and **R-02** are resolved.
> This is a major bump because Article VI now forbids implementation patterns
> that v1.1.1 permitted.
>
> **v2.1.0 — the logos were measured.** `arcoreimg` was run against all ten
> club logos for the first time. **Four score ≥ 75** after asset normalization,
> which is more than the grading gate needs — so ARCore Augmented Images can
> track the real logos directly, with no custom matcher, no ML classifier and no
> redesigned art. **D-20 is amended** (the three markers ratified in v2.0.0 were
> the three *worst* logos, one of which yields no keypoints at all) and **D-21**
> adds a mandatory normalization-and-measure step. Minor bump: no rule was
> loosened, and Article VI is unchanged.
>
> **v2.2.0 — context continuity.** Work on this repo is handed between different
> agents and models, so keeping documentation current is now a **governance
> obligation** (Governance §8), not a courtesy. `docs/agent-handoff.md` is the
> session entry point and MUST be updated before any task is reported done.
>
> **v2.2.1 — known debt caught up with AR-01…AR-03.** No rule changed. Debt #1
> and #3 still described a tree that no longer exists (`lib/ar/` missing, the
> `Timer` mock still the AR screen). Those statements are corrected so the next
> agent does not revive `ar_view_screen.dart`.
>
> **v2.2.2 — AR-05 code, detection not yet accepted.** No rule changed. Debt #1
> still said every capable device used `FakeArTracker`. That wiring is
> superseded: a capable device now starts `ArCoreImageTracker`. The device
> acceptance table is still empty (prints not measured). Plugin 1.1.3 hardcodes
> physical width at 0.2 m; `tools/patch_arcore_image_width.ps1` is the
> sanctioned way to pass `anchoMetros` — do not bump the pin and do not write a
> matcher to compensate.
>
> **v2.2.3 — AR-05 accepted on device.** No rule changed. The human confirmed
> Leones, Olmecas and Piratas lock, and that a blank wall and a non-registered
> club logo trigger nothing. Lock time was not stopwatched. Debt #1 no longer
> says the acceptance table is empty. 3D remains AR-06.
>
> **v2.2.4 — AR-06 code.** No rule changed. In-session 3D is a tracker `ARNode`
> plus GLB, never a WebView. Placeholder boxes ship so each marker has its own
> file. Device hold and dispose checks are still open.
>
> **v2.3.0 — full-project model catalog (branch `full-project`).** **D-03 is
> amended** and **D-22** is added. The grading *scan* minimum stays three
> measured markers (D-20). The product catalog on this branch is every Zona
> Sur club: one static stadium GLB and one animated player GLB. Same mesh
> family, team color and crest only. This does **not** make the other seven
> logos scannable. A matcher is still forbidden.
>
> **v2.3.1 — D-22 low-poly files exist.** No rule changed. `tools/write_lowpoly_glbs.py`
> writes the 20 GLBs (stadium static, player clips `idle` + `gesto`). Scan
> targets stay D-20. Debt #1 no longer says the catalog is missing.
>
> **v2.3.2 — AR-07 actions on the seam.** No rule loosened. `ArTracker` gains
> `playClip` and `setPresentationYaw`. Plugin 1.1.3 does not tick Filament
> clips until `tools/patch_filament_clips.ps1`. Actions exist only in
> `ArLocked`. Scan targets stay D-20. Device confirmation not run.
>
> **v2.4.0 — D-23 amends the D-22 scan clause.** Full-project completeness
> means every Zona Sur club is scannable. That does **not** put the other
> seven logos in the database. Bravos (already 90) enters the active set.
> The six logos that cannot be tracked get a marker card scored ≥ 75.
> Identity stays an exact name lookup. A matcher is still forbidden.
>
> **v2.4.1 — D-23 cards reversed.** The generated cards are not the product.
> The scan target is the club logo. The gate is `arcoreimg` **≥ 75**, not 90.
> Active logos: Leones 100, Olmecas 100, Piratas 100, Bravos 90, Tigres **raw**
> 75 (never normalize Tigres). Diablos and Guerreros at 50, and the three
> zero-keypoint logos, stay out — ARCore will not lock them.
>
> **v2.4.2 — D-23 scan set grows by measured logos only.** The Conspiradores
> wordmark scores 100 raw and is in. The earlier silhouette still does not
> clear 75. Águila and Pericos stay out until a file of theirs scores ≥ 75.
>
> **v2.4.3 — D-23 Águila crest.** Of four later Águila files, the crest scores
> 100 raw and is in. The wordmark also scores 100 raw but carries a +N
> watermark and was not shipped. The red swoosh has no keypoints; the "A"
> plus eagle head scores 20. Do not re-encode the crest (100 → 90). Pericos
> stays out until a file of theirs scores ≥ 75.
>
> **v2.4.4 — D-23 Pericos wordmark.** First of five candidates. Raw 100.
> Shipped as-is. The other four were not scored. Every Zona Sur club now
> has a scan target. Do not re-encode the wordmark.

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
| AR | **Flutter-native (D-01)** — ARCore/ARKit Augmented Images behind an `ArTracker` seam (D-12) | `lib/ar/`, `lib/screens/ar/` | AR-05 accepted on device. AR-06 places a GLB on the pose; AR-07 code plays `idle`/`gesto` and speaks `infoTexto` only in `ArLocked`. Device hold/dispose and action confirmation not checked. Demo only with `LMB_AR_DEMO`. |
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

### VI. Flutter-native AR behind an enforced boundary (D-01, D-12 … D-20)

**Ratified engine: Flutter-native.** Do **not** enable `flutter_unity_widget` or
add a Unity project.

This article was rewritten in v2.0.0 after AR attempt #1 collapsed. It is now
prescriptive on purpose. The full contract is
[`docs/ar-architecture.md`](./docs/ar-architecture.md); the reasoning for each
rule is [`docs/ar-postmortem.md`](./docs/ar-postmortem.md). Both are normative.

#### VI.1 The governing principle

> **Flutter decides *what* to show. The platform tracker decides *what is
> there*. Neither may do the other's job.**

Attempt #1 failed because Dart tried to answer "what is the camera looking at?".
That question belongs to ARCore/ARKit. Dart's responsibility begins once a
deterministic **identity string** arrives.

#### VI.2 One detector, one renderer, one seam (D-12, D-16)

- Detection is **ARCore/ARKit Augmented Images**, accessed only through the
  `ArTracker` interface in `lib/ar/ar_tracker.dart`.
- The AR plugin may be imported by files in `lib/ar/trackers/` and **nowhere
  else**. Screens MUST NOT know which plugin exists.
- Exactly **one** production detector and **one** production renderer may be
  active. Attempt #1 ran three overlapping mechanisms at once.
- 3D inside a live camera session is rendered by the tracker's scene graph
  (`ARNode` + GLB). A **WebView-based viewer (`model_viewer_plus`) MUST NOT be
  presented as AR** — it cannot composite onto a camera feed. It is permitted
  only on an explicitly non-camera "Galería 3D" screen.

#### VI.3 Marker identity is deterministic, never scored (D-14, D-15)

- Identity comes from the reference-image name registered in the tracking
  database, resolved through an **exact map lookup** in `MarkerRegistry`.
- An unrecognised name resolves to nothing and the session keeps searching. The
  app MUST NOT guess.
- **Forbidden in any production code path:** perceptual/average/difference
  hashes, hue or saturation histograms, "edge energy", weighted similarity
  scores, tuned accept thresholds, nearest-neighbour fallbacks, or preferring a
  hinted team to break a tie. Attempt #1's 612-line `LogoMatcherService` is the
  canonical anti-pattern.
- `package:image` is **dev-tooling and test only**. It MUST NOT appear in a
  runtime path. Dart MUST NOT decode camera frames.

#### VI.4 Markers are measured, never assumed (D-13, D-21)

ARCore extracts **grayscale** feature keypoints, and Google's documentation names
*logos and line art* as unsuitable reference images. Attempt #1 assumed the club
logos would work, never measured them, and wrote a custom matcher to compensate.

The rule is therefore **measure, then decide** — not "logos are banned":

- Every reference image MUST score **≥ 75** on `arcoreimg eval-img`, and the
  score MUST be recorded in `docs/ar-marker-guide.md`. This is a merge gate.
- Reference images MUST be normalized first (D-21): alpha flattened onto
  **white**, short side ≥ 512 px, 24-bit without alpha. Re-score afterwards and
  ship whichever variant scores higher — normalization can also *reduce* a
  score.
- A club logo that scores ≥ 75 **is** a legitimate tracking target. Four of the
  original ten files do (D-20). Later files join the scan set under D-23 when
  they score ≥ 75.
- A logo that cannot reach 75 gets a **marker card**: the logo (for the human)
  over an irregular, high-contrast, non-repeating texture with asymmetric text.
- A low score is fixed in the **art or the asset pipeline** — **never** by
  compensating in code.
- Physical prints: ≥ 15 cm, flat, **matte** paper. Must fill ≥ 25 % of the
  camera frame to be detected.
- Reference image filename stem MUST equal the `Marcador.id`.

#### VI.5 Session state is a sealed machine, not loose booleans

- AR state is one `ArSessionState` value: `ArPreparing`, `ArSearching`,
  `ArCandidate`, `ArLocked`, `ArLost`, `ArFailed`.
- AR widgets MUST NOT add their own detection booleans. Attempt #1 kept
  `_detectedTeam` / `_demoMode` / `_detectionTimer` on a `StatefulWidget`, and
  every unrepresentable combination was a bug.
- Reaching content **without** a confirmed detection is forbidden — that is the
  `BUG-01` regression.
- A detection MUST be confirmed by a debounce gate (same identity N consecutive
  times, default 2) before content renders.

#### VI.6 Demo mode is explicit and honest

- Demo mode is the `FakeArTracker`, entered only by explicit user action or
  `--dart-define=LMB_AR_DEMO=true`.
- It is **never** the automatic fallback for a failed real session; that is
  `ArFailed` with recovery actions.
- Demo content MUST render the `MODO DEMO` badge, and MUST cycle all registered
  markers rather than defaulting to one club.

#### VI.7 Failures are typed, in Spanish, and always escapable

Every `ArTrackerFailure` maps to defined Spanish copy plus at least one recovery
action — at minimum the manual team path (Article III). No silent failures, no
red screens. "Marker not recognised" is **not** an error; it is still searching.

#### VI.8 Native configuration is deliberate (D-17)

Permitted: `minSdk = 24`, `CAMERA` permission, `com.google.ar.core` meta-data as
`optional`, the `com.google.ar.core` `<queries>` entry.

**Forbidden without an amendment**, each because it broke attempt #1:

- `isDebuggable = false` on the **debug** build type — it disables debugging
  repo-wide to smooth one screen.
- Hardcoding `compileSdk` past the Flutter stable default.
- A manual `com.google.ar:core` Gradle dependency racing the plugin's own.
- Gradle JDK auto-download / foojay toolchain resolution.

AR plugin versions are **exactly pinned** (no caret). Native edits are their own
commit with a stated reason and rollback note.

#### VI.9 Verification (D-18)

- Unit tests cover the state machine, debounce and registry against
  `FakeArTracker`.
- Recognition quality is proven **only** by a device acceptance run on a
  physical Android device, recorded in the work item, including a blank-wall and
  a wrong-club control row that MUST show zero false positives.
- A test that loads a bundled asset and asserts the matcher returns that asset's
  id proves nothing and MUST NOT be cited as evidence.
- One slice per branch, each independently device-verifiable.

#### VI.10 Contingency is pre-authorised (D-19)

If acceptance cannot be passed with well-scoring cards, do **not** write a custom
matcher. Implement the sanctioned `HybridMarkerTracker`: identity from a
QR/DataMatrix code printed on the same card, pose from ARCore plane detection.
Anything else requires an amendment.

#### VI.11 Minimum academic AR bar (see Grading checklist)

- ≥ **3 distinct scannable markers**, each with **specific** content.
- In the AR window: interactive buttons with ≥ **2 action types** (e.g. play
  animation, show info + TTS/narration, play video, show simulated stats,
  particles/VFX).
- Multiple interaction modes (e.g. galería AR, trivia AR, videos inmersivos).
- AR chrome MUST match main app style (colors, type, icons, layout language).

**3D content (D-03, D-22):** On `full-project`, every Zona Sur club has two
GLBs — a static stadium and an animated player. Same mesh family; team color
and crest are the only differences. Only the player has clips (`idle`,
`gesto`). Budget: ≤ 4 MB and ≤ 50 k triangles per GLB. The scan database stays
the logos that score ≥ 75 (D-13). That is not a 90 cutoff. Tigres ships
as the raw logo (75). Logos at 50 or with zero keypoints are not scan
targets.

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
    ar/            AR scan + locked surfaces
  widgets/         reusable UI
  models/          Equipo, Trivia, Marcador, VideoItem, …
  ar/              ArTracker seam, session controller, MarkerRegistry
    trackers/      the ONLY place an AR plugin may be imported
  services/        DataService, FilterEngine, StatsSimulator, Feedback, …
  data/            demo / mock helpers
  theme/           colors, theme, assets keys
  utils/           pure helpers
assets/            data.json, ar_markers.json, images, markers, models, sfx
docs/              binding technical annexes
tools/             dev scripts (marker scoring, …)
```

- Navigation via `AppRoutes` + `onGenerateRoute`.
- I/O in `services/`, not inside `build()`.
- UI MUST NOT hard-code a specific AR plugin API — go through `ArTracker`
  (Article VI.2). The layering check is a grep:
  `rg -l "ar_flutter_plugin" lib/ | rg -v "^lib/ar/trackers/"` must print
  nothing.

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
| AR markers (≥3) | 5 logos in DB (scores ≥ 75); 3 accepted on device | Gate is 75, not 90. Human: Leones, Olmecas, Piratas lock. Bravos and Tigres raw are not device-checked. |
| AR controls | Code (AR-07); device not checked | ≥2 action types on `ArLocked` only: gesto (`idle`/`gesto`) and información (`infoTexto` + TTS + one 360°). |
| Simulated live stats | Planned | Local mock “tiempo real”. |
| Multiple AR modes | Planned | e.g. galería, trivia AR, video inmersivo. |
| Team search | Partial → required | Client-side name filter on team list. |
| User feedback | Partial | Sounds + visual state + short messages. |

### Failure modes agents MUST handle

- Camera / mic permission denied → Spanish copy + manual team path.
- Marker not recognized → keep searching; never crash; offer manual select. This
  is **not** an error state (Article VI.7).
- ARCore missing / unsupported device → typed failure with recovery, never a
  silent slide into fake detection (Article VI.6).
- Missing 3D asset → graceful fallback, not a red screen.
- Remote video URL fails → placeholder + message; app stays stable.
- Low-end device → prefer lighter models/effects; avoid unbounded particle spam.

The full failure → Spanish copy mapping is
[`docs/ar-architecture.md` §8](./docs/ar-architecture.md#8-error-taxonomy--user-facing-spanish-copy).

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
- Key markers/assets by stable ids; reference-image filename stem == `Marcador.id`.
- Implement only **allowed** video filters; never ship forbidden ones.
- Keep `flutter analyze` clean on touched files when practical.
- Pin AR plugin versions exactly (no caret).
- Score every marker with `arcoreimg eval-img` ≥ 75 and record it.

SHOULD:

- Facades: `ArTracker`, `FilterEngine`, `StatsSimulator`, `FeedbackService`.
- Asset layout: `assets/markers/`, `assets/models/<marcador_id>/`, `assets/sfx/`.
- Optimize 3D (compressed GLB ≤ 4 MB / ≤ 50 k tris, one VFX at a time).

MAY:

- TTS for “Información” narration.
- SharedPreferences for last trivia score.
- Widget/unit tests for filters, trivia scoring, JSON parsing.
- `model_viewer_plus` on a non-camera "Galería 3D" screen only.

MUST NOT:

- Add Unity, a backend API, or login/auth.
- Expand beyond Zona Sur baseball without amendment.
- Ship forbidden filters.
- Commit secrets or huge raw capture dumps.
- Treat mock/demo detection as production recognition.
- Hand-roll image recognition in Dart (hashes, histograms, similarity scores,
  tuned thresholds) anywhere in a production path.
- Decode camera frames in Dart, or use `package:image` at runtime.
- Use bare club logos as tracking targets.
- Present a WebView 3D viewer as an AR experience.
- Import an AR plugin outside `lib/ar/trackers/`.
- Apply any forbidden native config from Article VI.8.

---

## Known debt (do not "fix" casually)

1. **Model catalog is low-poly procedural (D-22).** 20 GLBs ship under
   `assets/models/<club_id>/` (`estadio.glb` static, `jugador.glb` with
   `idle` and `gesto`). Same mesh family; kit color only. The player is an
   articulated biped (node TRS, not skinned). Generator:
   `tools/write_lowpoly_glbs.py`. `docs/model-prompts.md` is the upgrade
   path for nicer art. Do not add unmeasured logos to the scan database
   to “cover” the other seven clubs, and do not write a matcher.
2. **In-session 3D is coded, not device-checked (AR-06).** `attachModel`
   places a per-marker GLB on the fully-tracked pose. Leones uses the
   stadium mesh; Olmecas uses the player mesh; Piratas is still the
   trophy box. Do not put a WebView on the camera. Still open: model
   holds on the card, and enter/leave AR 5 times does not crash. Plugin
   1.1.3 hardcodes width at 0.2 m and never ticks Filament clips. After
   `flutter pub get` re-run `tools/patch_arcore_image_width.ps1` and
   `tools/patch_filament_clips.ps1`. Do not bump the pin and do not write
   a matcher. AR-07 buttons are coded, not confirmed on a device.
3. **Markers shipped; prints pending.** Ten logos are in
   `assets/markers/`, each scoring ≥ 75. Tigres is the **raw** JPEG — do not
   normalize it. Remaining: print at ≥ 15 cm matte and record `anchoMetros`.
   The flame Diablos logo scores 80, the Guerreros shield scores 90 raw,
   the Conspiradores wordmark scores 100 raw, the Águila crest scores
   100 raw, and the Pericos wordmark scores 100 raw. All five are in. Do
   not flatten those raw copies. Do not re-encode the Águila crest or the
   Pericos wordmark. The first Conspiradores, Águila, and Pericos files
   do not. Every Zona Sur club now has a scan target.
4. **Timer mock deleted (AR-03).** `lib/screens/ar_view_screen.dart` is gone.
   The AR route is `ArScanScreen`. Do not restore the `Timer` or the Guerreros
   default. Scan UI must keep reading `ArSessionState` only.
5. **Video filter UI missing.**
6. **Highlights/videos still demo** — swap to real remote URLs (R-03).
7. **Tests exist for the AR core** (`marker_registry`, session controller, scan
   screen). Device acceptance for real detection is recorded on AR-05; do not
   treat an asset-vs-itself test as proof.
8. **README still Flutter template.**
9. **`flutter_unity_widget` comment in `pubspec.yaml`** — leave unused; do not
   activate. Delete it when Article VI work lands.
10. **Parallel English domain (Article IV violation)** — `models/team.dart`
   (`Team`, `name`, `city`, `history`) and `models/trivia_question.dart`
   (`TriviaQuestion`, `prompt`) duplicate `Equipo` / `Trivia`, and are reachable
   from `data/mock_data.dart` and `data/demo_highlights.dart`. Consolidate onto
   the Spanish domain in a dedicated cleanup item — do not extend them.

Track fixes via `WORK_ITEMS.md`.

---

## Decisions log

| ID | Decision | Status |
|---|---|---|
| D-01 | AR engine = **Flutter-native (A)**. Unity rejected. | **Ratified 2026-09-04** |
| D-02 | **Android + iOS**; primary testing **Android**. | **Ratified 2026-09-04** |
| ~~D-03 (v2.2.4)~~ | ~~3D = estadios / trofeos / pelotas / jugadores históricos; student- or AI-authored; interactive animations.~~ **Amended by D-22** on `full-project` — required models are stadium + player per club. | ~~Ratified 2026-09-04~~ |
| D-03 | 3D is student- or AI-authored. On `full-project`: **one stadium and one player per Zona Sur club** (20 GLBs). Shared mesh, team color and crest only. Only the player is animated. | **Amended 2026-09-07** |
| D-04 | Scholar use OK for marks; logos **not yet collected** — blocking real scan QA until ≥3 markers exist. | **Ratified 2026-09-04** |
| D-05 | Graded feature = **video catalog + filters** (allowed/forbidden lists). Still photos out of MVP. | **Ratified 2026-09-04** |
| D-06 | **No API**; local JSON + assets; media via URLs only. | **Ratified 2026-09-04** |
| D-07 | Videos/highlights = **remote URLs**. | **Ratified 2026-09-04** |
| D-08 | **No logins**; optional **last trivia score** on device only. | **Ratified 2026-09-04** |
| D-09 | No hard deadline; ship against **grading checklist** until human says enough. | **Ratified 2026-09-04** |
| D-10 | Team list includes **client-side name search/filter**. | **Ratified 2026-09-04** |
| D-11 | Marker AR requires scan; manual path uses **Abrir experiencia AR** → scanner. | **Ratified 2026-09-04** |
| D-12 | Detection = **ARCore/ARKit Augmented Images** via `ar_flutter_plugin_plus`, **exactly pinned**, reachable only through the `ArTracker` interface. One production detector. Resolves R-01. | **Ratified 2026-09-07** |
| D-13 | Tracking targets are **designed marker cards**, not club logos. `arcoreimg eval-img` **≥ 75** is a merge gate; ≥ 15 cm matte print. | **Ratified 2026-09-07** |
| D-14 | Marker identity is a **deterministic exact lookup** of the tracker's reference-image name. Similarity scores and tuned thresholds are forbidden. | **Ratified 2026-09-07** |
| D-15 | **No hand-rolled CV in production.** No Dart frame decoding; `package:image` is dev/test only. | **Ratified 2026-09-07** |
| D-16 | In-session 3D uses the tracker scene graph. **WebView viewers may never be presented as AR**; `model_viewer_plus` is limited to a non-camera Galería 3D. | **Ratified 2026-09-07** |
| D-17 | Native/toolchain config is deliberate and reversible. Debug stays debuggable; no `compileSdk` jumps, no manual ARCore dep, no JDK auto-download. | **Ratified 2026-09-07** |
| D-18 | AR slices ship one per branch and are proven by a **device acceptance run** with blank-wall and wrong-club controls. Asset-vs-itself tests prove nothing. | **Ratified 2026-09-07** |
| D-19 | Pre-authorised contingency = **`HybridMarkerTracker`** (QR/DataMatrix id on the card + ARCore plane pose). No other fallback without amendment. | **Ratified 2026-09-07** |
| ~~D-20 (v2.0.0)~~ | ~~First grading markers = estadio/Diablos Rojos, jugador/Guerreros de Oaxaca, trofeo/Pericos de Puebla.~~ **Superseded** — chosen before measuring; they score 50, 50 and *no keypoints*. | ~~Ratified 2026-09-07~~ |
| D-20 | First grading markers = **estadio/Leones de Yucatán (100)**, **jugador/Olmecas de Tabasco (100)**, **trofeo/Piratas de Campeche (100)**, spare **pelota/Bravos de León (90)** — three distinct `tipo`, all measured with `arcoreimg`. Resolves R-02. | **Amended 2026-09-07** |
| D-21 | Reference images MUST be **normalized and measured** before use: alpha flattened onto **white**, short side ≥ 512 px, 24-bit no-alpha, then re-scored. Ship whichever variant scores higher and record it. Normalization is not assumed to help — it lowered one logo 75 → 50. | **Ratified 2026-09-07** |
| D-22 | **Full-project catalog** (branch `full-project`): every club gets `estadio.glb` (static) and `jugador.glb` (clips `idle` + `gesto` only). Same meshes, color and crest differ. **Scan-set sentence amended by D-23.** Do not add unmeasured logos, and do not write a matcher. | **Amended 2026-09-08** |
| ~~D-23 (cards)~~ | ~~Six untrackable logos get generated marker cards.~~ **Reversed the same day.** The scan target is the club logo, not a substitute card. | ~~Ratified 2026-09-08~~ |
| D-23 | **Scan set = logos that score ≥ 75, not 90, and not substitute cards.** Active logos: Leones 100, Olmecas 100, Piratas 100, Bravos 90, Tigres raw 75, Diablos flame 80, Guerreros shield raw 90, Conspiradores wordmark raw 100, Águila crest raw 100, Pericos wordmark raw 100. Do not normalize Tigres, the Guerreros shield, the Conspiradores wordmark, the Águila crest, or the Pericos wordmark. The old 50-score files and the first Conspiradores, Águila, and Pericos files stay out. The Águila wordmark also scored 100 raw but was not shipped (it carries a +N watermark). The other Pericos candidates were not scored. No matcher. | **Amended 2026-09-08** |

Open residual (non-blocking for backlog writing):

| ID | Notes |
|---|---|
| ~~R-01~~ | ~~Exact plugin choice for image tracking + 3D.~~ **Resolved by D-12.** |
| ~~R-02~~ | ~~Which 3 of 10 teams (or objects) are the first scannable markers.~~ **Resolved by D-20.** |
| R-03 | Final remote video URL list (baseball-themed). |
| R-04 | Whether `ar_flutter_plugin_plus` survives device acceptance. It is a young, low-adoption fork; D-19 is the ratified escape hatch if it does not. |

---

## Governance

1. **This file wins.** `AGENTS.md` tells agents how to work. `WORK_ITEMS.md`
   holds executable prompts. `README.md` tells humans how to run the app.
2. **Binding annexes.** `docs/ar-architecture.md` and `docs/ar-marker-guide.md`
   are normative extensions of Article VI and carry the same authority. Where an
   annex is more specific than Article VI, the annex governs the detail; where
   they conflict outright, this file wins and the annex must be corrected in the
   same change. `docs/ar-postmortem.md` is the historical record — it may be
   appended to but MUST NOT be deleted or softened.
3. **Amendments** require rationale, article touched, and version bump (patch /
   minor / major). Update **Last Amended**.
4. **Code that violates an article** is allowed only as documented known debt
   being fixed by the active work item.
5. **Ambiguity:** ask the human — especially marker art, video URLs, and
   model sourcing. Do not re-open Mundial branding; theme is baseball. Do not
   re-open Unity.
6. **Review gate:** change is not done until constitution/data/routes still
   match, grading gates are not regressed, and forbidden filters were not added.
   For AR changes, the checklist in
   [`docs/ar-architecture.md` §14](./docs/ar-architecture.md#14-review-checklist-for-any-ar-change)
   must also pass.
7. **Repeating a postmortem root cause is a blocking review failure**, even if
   the code works locally. Cite the RC id when rejecting.
8. **Context continuity is part of the deliverable.** No task is complete until
   the documentation matches reality. Every session MUST update
   `docs/agent-handoff.md` (state, session log, environment gotchas) and the
   status of its item in `WORK_ITEMS.md`; other documents are updated when the
   change touches them (see `AGENTS.md` → "Documentation pass"). Work is
   frequently handed between different agents and models, so an undocumented
   discovery is a discovery that will be paid for twice. Reversing a previous
   decision MUST be stated explicitly with its rationale, never applied
   silently.
