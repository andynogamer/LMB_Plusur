# LMB Plusur — Work Items para Agentes

> Backlog after Constitution **v1.1.0** (decisions D-01…D-11 + professor
> checklist). Each item is a **copy-paste prompt**. One item per branch/PR.
> Format: contexto → tarea → criterios de aceptación → archivos → fuera de alcance.
>
> Theme: **LMB baseball Zona Sur**. “Mundial 2026” in the professor PDF is
> leftover from the old brief — meet those *technical* bars with baseball
> content only (Constitution theme note).

## Leyenda

| Campo | Valores |
|---|---|
| **Tipo** | 🐛 Bug · 📗 User Story · 🔧 Spike |
| **Prioridad** | 🔴 P0 · 🟠 P1 · 🟡 P2 · 🟢 P3 |
| **Estado** | ☐ Pendiente · ◐ En progreso · ☑ Hecho |

## Índice

| ID | Tipo | Prio | Título | Estado | Checklist map |
|---|---|---|---|---|---|
| US-01 | 📗 | 🟠 P1 | Team list name search (D-10) | ☑ | UI |
| US-02 | 📗 | 🟠 P1 | Abrir experiencia AR from team menu (D-11) | ☑ | AR entry |
| US-03 | 📗 | 🟠 P1 | Last trivia score on device (D-08) | ☑ | Bonus/trivia |
| US-04 | 📗 | 🟡 P2 | Action feedback sounds + visual states | ☑ | UX |
| SP-01 | 🔧 | 🔴 P0 | Flutter-native AR spike (R-01) | ☐ | AR foundation |
| US-05 | 📗 | 🔴 P0 | Marker + asset data model (≥3 marcadores) | ☐ | 3 markers |
| US-06 | 📗 | 🔴 P0 | Real marker scanning replaces AR mock | ☐ | 3 markers |
| US-07 | 📗 | 🔴 P0 | AR window: 3D model + style-matched controls | ☐ | Buttons / UI |
| US-08 | 📗 | 🔴 P0 | ≥2 AR action types (anim, info+TTS, …) | ☐ | 2 action types |
| US-09 | 📗 | 🟠 P1 | Simulated live stats in AR / team | ☐ | Actions |
| US-10 | 📗 | 🟠 P1 | Multiple AR modes (galería / trivia / video) | ☐ | Bonus + modes |
| US-11 | 📗 | 🔴 P0 | Video archive UI (remote URLs) | ☐ | Videos |
| US-12 | 📗 | 🔴 P0 | Video filters — allowed set only | ☐ | Filters |
| US-13 | 📗 | 🟠 P1 | Baseball-coherent 3D animations / VFX | ☐ | 15pt effects |
| US-14 | 📗 | 🟡 P2 | Performance pass (load / stability) | ☐ | 15pt perf |
| US-15 | 📗 | 🟡 P2 | Android APK release build | ☐ | Packaging |
| US-16 | 📗 | 🟢 P3 | README product brief for humans | ☐ | Docs |
| BUG-01 | 🐛 | 🟡 P2 | AR mock detects only Guerreros / first team | ☐ | Fixed by US-06 |

**Human blockers (not agent-solo):** collect ≥3 printable logos/markers (D-04 /
R-02); supply baseball remote video URLs (R-03); author or generate GLB models
(D-03); record explanatory demo video (10pt).

---

# 📗 USER STORIES

## US-01 · 🟠 P1 · Team list name search (D-10) · ☑ Hecho

**Prompt**
```
Contexto: Constitution D-10 requires client-side name search on the team list.
TeamListScreen today lists all Zona Sur clubs with no filter.

Tarea: Add a Spanish search field that filters equipos by nombre (case-
insensitive, accent-tolerant if practical). Empty query shows all teams.
Reuse AppColors / existing list tiles. Keep navigation to TeamMenuScreen.

Criterios de aceptación:
- Typing filters the visible list without leaving the screen.
- Clearing the field restores the full list.
- No backend; filter in memory from DataService data.
- flutter analyze clean on touched files.

Archivos: lib/screens/team_list_screen.dart (and small widget extract if needed)
Fuera de alcance: server search, fuzzy ranking libraries, AR changes.
```

---

## US-02 · 🟠 P1 · Abrir experiencia AR from team menu (D-11) · ☑ Hecho

**Prompt**
```
Contexto: D-11 — manual path must offer “Abrir experiencia AR” that launches
the scanner (optionally hinting the team logo). Full marker AR still requires
a real scan (or labeled demo until US-06).

Tarea: Add a FeatureCard on TeamMenuScreen that navigates to the AR route,
passing the selected Equipo as a hint argument. AR screen shows Spanish copy
like “Apunta al logo de {nombre}”. Do not auto-complete detection without
camera recognition unless demo mode is explicitly labeled.

Criterios de aceptación:
- Team menu has the new entry, styled like other FeatureCards.
- AR screen receives optional equipo hint and shows it in UI copy.
- Manual path still exposes historia / trivia / highlights as today.

Archivos: lib/screens/team_menu_screen.dart, lib/screens/ar_view_screen.dart,
lib/app.dart or routes if arguments need wiring
Fuera de alcance: real CV tracking (SP-01 / US-06), 3D models.
```

---

## US-03 · 🟠 P1 · Last trivia score on device (D-08) · ☑ Hecho

**Prompt**
```
Contexto: D-08 — no logins; may persist only the last trivia score per team
(or globally last score) on device.

Tarea: After trivia results, save the latest score with shared_preferences
keyed by equipo.id. Show “Último puntaje: X” on TeamMenuScreen and/or trivia
entry. Overwrite on each completed run.

Criterios de aceptación:
- Completing trivia updates the stored last score.
- Relaunching the app still shows the last score.
- No account UI.

Archivos: pubspec.yaml, new small service under lib/services/, team_menu and
trivia_results screens
Fuera de alcance: leaderboards, cloud sync, multi-score history.
```

---

## US-04 · 🟡 P2 · Action feedback sounds + visual states · ☑ Hecho

**Prompt**
```
Contexto: Professor requires visual/auditory feedback on actions.

Tarea: Introduce a tiny FeedbackService (short AssetSource sfx + optional
HapticFeedback). Use it on primary FeatureCard taps, trivia answer select,
and AR placeholder buttons. Buttons should show pressed/selected state.
Short Spanish SnackBar where helpful (“Respuesta guardada”, etc.).

Criterios de aceptación:
- At least 2 distinct short sounds bundled under assets/sfx/.
- Primary navigation actions play feedback without being annoying on spam
  (debounce or very short clips).
- Visual pressed/selected states visible on key buttons.

Archivos: lib/services/feedback_service.dart, assets/sfx/, widgets/screens that
wire it
Fuera de alcance: full design rewrite, background music.
```

---

## SP-01 · 🔴 P0 · Flutter-native AR spike (R-01) · ☐ Pendiente

**Prompt**
```
Contexto: D-01 ratified Flutter-native AR. Need a concrete plugin path for
Android-first image-marker tracking + GLB display that agents can maintain.

Tarea: Spike only — compare 1–2 Flutter-compatible approaches (e.g. ARCore
augmented images / community plugins / camera + on-device matcher + model
viewer). Document choice in a short markdown note under docs/ar-spike.md
(or amend Constitution R-01). Prove on Android: detect one test image and
show one placeholder GLB or primitive. No Unity.

Criterios de aceptación:
- Written recommendation with pros/cons and chosen stack.
- Minimal runnable Android demo path documented (commands + permissions).
- Constitution R-01 updated or spike doc linked from AGENTS.md Current phase.

Archivos: docs/ar-spike.md (create), pubspec experimental deps OK on a branch,
android manifest permissions as needed
Fuera de alcance: production UI polish, all 10 teams, iOS hardening, filters.
```

---

## US-05 · 📗 · 🔴 P0 · Marker + asset data model (≥3 marcadores) · ☐ Pendiente

**Prompt**
```
Contexto: Grading needs ≥3 distinct scannable elements with specific content.
Logos may still be placeholders (D-04).

Tarea: Extend local data with a marcadores (or ar_objetos) collection: id,
equipoId (optional), tipo (estadio|trofeo|pelota|jugador), modelAsset path,
markerImage path, titulo, infoTexto, videoUrl?, animaciones[]. Wire models +
DataService. Seed **at least 3** entries (placeholder images/models OK).

Criterios de aceptación:
- JSON parses into typed Dart models.
- Three markers load in app debug (list or log).
- Ids stable and documented in constitution Known debt / R-02 if team picks
  change.

Archivos: assets/data.json (or assets/ar_markers.json), lib/models/, 
lib/services/data_service.dart
Fuera de alcance: real CV, fancy meshes (placeholders fine).
```

---

## US-06 · 📗 · 🔴 P0 · Real marker scanning replaces AR mock · ☐ Pendiente

**Prompt**
```
Contexto: ArViewScreen uses a Timer fake detection. SP-01 chose the stack.

Tarea: Replace mock with real image/marker recognition for the ≥3 markers
from US-05. On detect, resolve marcador id → show AR session content. Keep
Spanish failure/retry UX and link to manual team select. Label demo mode if
fallback remains.

Criterios de aceptación:
- Detecting each of 3 test markers yields the correct specific content id.
- Unknown image does not crash; user can retry.
- BUG-01 behavior (always Guerreros) is gone in non-demo mode.

Archivos: lib/screens/ar_view_screen.dart, AR facade/service, Android
permissions/Gradle as required by plugin
Fuera de alcance: all filter work, full VFX pack (US-13).
```

---

## US-07 · 📗 · 🔴 P0 · AR window 3D + style-matched controls · ☐ Pendiente

**Prompt**
```
Contexto: Professor — AR UI must match main page style; show 3D for scanned
content.

Tarea: After detection, render the marker’s 3D model in the AR/view surface
and overlay controls using AppColors, Poppins, FeatureCard/PrimaryButton
patterns (not a foreign Material default look). Include clear back/exit.

Criterios de aceptación:
- Model for the detected marker appears (placeholder GLB OK).
- Overlay visually consistent with MainScreen language.
- Works on Android test device/emulator path documented in spike.

Archivos: AR screen/widgets/theme reuse
Fuera de alcance: implementing every action (US-08), particle spectacle (US-13).
```

---

## US-08 · 📗 · 🔴 P0 · ≥2 AR action types · ☐ Pendiente

**Prompt**
```
Contexto: Checklist — interactive buttons with ≥2 action types.

Tarea: In the AR overlay implement at least two of:
1) Activar animación del modelo (idle → celebración/gesto).
2) Información: rotate 360° + dialog with datos + TTS/narración aloud.
3) Reproducir video promocional/histórico (URL).
4) Efecto VFX simple (particles/light/banner).
Wire FeedbackService. Spanish labels.

Criterios de aceptación:
- ≥2 distinct action types work end-to-end on a detected marker.
- Info action shows dialog with content from data, not hardcoded English.
- Actions give visual and/or audio feedback.

Archivos: AR overlay widgets, services (tts/video), marker JSON fields
Fuera de alcance: full multi-mode switcher (US-10) unless cheap to stub.
```

---

## US-09 · 📗 · 🟠 P1 · Simulated live stats · ☐ Pendiente

**Prompt**
```
Contexto: Professor asks for realtime stats/results simulated for the prototype.

Tarea: Add a StatsSimulator (timer-based updating scores/innings/hits) shown
in AR and/or team menu. Data is fake, baseball-flavored, Spanish labels.
Not a network API.

Criterios de aceptación:
- Numbers change over time without user spam-tapping.
- UI readable and themed.
- No real LMB API calls.

Archivos: lib/services/stats_simulator.dart, AR/team UI wiring
Fuera de alcance: real sports data feeds.
```

---

## US-10 · 📗 · 🟠 P1 · Multiple AR modes · ☐ Pendiente

**Prompt**
```
Contexto: Experiencias múltiples — galería AR, trivia AR, videos inmersivos.

Tarea: After scan (or from AR hub), let user switch modes: Galería AR
(model focus), Trivia AR (reuse trivia questions overlay), Video inmersivo
(play catalog/marker video in AR chrome). Same visual system. Counts as
bonus/extra mode for grading.

Criterios de aceptación:
- ≥2 modes reachable in one AR session.
- Mode switch has feedback.
- Trivia AR reuses equipo/marcador trivia data where linked.

Archivos: AR hub/mode widgets, routes if needed
Fuera de alcance: building a separate Unity scene graph.
```

---

## US-11 · 📗 · 🔴 P0 · Video archive UI (remote URLs) · ☐ Pendiente

**Prompt**
```
Contexto: D-05/D-07 — baseball video acervo with remote URLs; filters come in
US-12.

Tarea: Add a Videos screen (from main and/or team menu) listing catalog
entries from local JSON (titulo, descripcion, url, equipoId?). Play with
existing video_player patterns. Handle URL failure gracefully. Spanish UI
matching theme.

Criterios de aceptación:
- User can open catalog and play at least one remote URL (use a known public
  sample URL if final list pending R-03).
- Broken URL shows Spanish error, app stable.
- No API server.

Archivos: assets data, models, new screen, app_routes, menus
Fuera de alcance: filter pipeline (US-12), downloading entire files for offline.
```

---

## US-12 · 📗 · 🔴 P0 · Video filters — allowed set only · ☐ Pendiente

**Prompt**
```
Contexto: Constitution Article VII — MUST implement blur, pixelate, thermal,
color adjust, and custom (soft / pastel / high saturation). MUST NOT
implement B&W, grayscale, sepia, exposure, invert.

Tarea: On the video player/editor UI, let user preview apply each allowed
filter family (at least one control per family). Custom section includes
suavizado, pasteles, alta saturación. Guard code reviews: no forbidden
filters in enums/UI. Prefer on-device fragment shaders or image/video frame
processing that keeps playback usable on mid Android phones.

Criterios de aceptación:
- All allowed families reachable in UI with visible effect.
- Forbidden filters absent from UI and code enums.
- Feedback on filter select (US-04 service if present).
- Baseball-themed copy (“Filtros del partido”, etc.).

Archivos: FilterEngine service, video screen widgets, shaders/assets if any
Fuera de alcance: still-photo camera product, uploading filtered video.
```

---

## US-13 · 📗 · 🟠 P1 · Baseball-coherent 3D animations / VFX · ☐ Pendiente

**Prompt**
```
Contexto: 15pt rubric — animations/effects coherent with theme (baseball).

Tarea: Polish at least one celebration animation and one simple VFX
(particles or light burst or banner) tied to AR actions. Keep performance
reasonable (US-14 will tune). Models remain student-supplied placeholders OK.

Criterios de aceptación:
- Animation/VFX clearly baseball-flavored (not soccer Mundial branding).
- Triggered from AR controls.
- Does not drop the AR session on mid-tier Android when toggled a few times.

Archivos: model animation hooks, VFX widget/plugin usage
Fuera de alcance: cinematic cutscenes, Unity.
```

---

## US-14 · 📗 · 🟡 P2 · Performance pass · ☐ Pendiente

**Prompt**
```
Contexto: 15pt — load time and stability on mobile.

Tarea: Profile Android run: splash→main, AR enter, video+filter. Fix obvious
jank (huge images, unbounded rebuilds, missing dispose). Lazy-load heavy
assets. Document before/after notes briefly in docs/performance.md.

Criterios de aceptación:
- No crashes on happy path through scan mock/real + video filter.
- Disposed controllers (video, AR, animation) verified.
- Notes filed for the explanatory video / defense.

Archivos: as needed + docs/performance.md
Fuera de alcance: rewriting entire architecture.
```

---

## US-15 · 📗 · 🟡 P2 · Android APK release build · ☐ Pendiente

**Prompt**
```
Contexto: Packaging gate — APK for Android (IPA optional later).

Tarea: Ensure release signing instructions (debug OK for class if allowed),
flutter build apk succeeds, document install steps in README. Fix any
release-only crashes from Proguard/permissions.

Criterios de aceptación:
- `flutter build apk` succeeds on the project.
- README section: how to install on a phone.
- App launches past splash on a physical Android device or emulator.

Archivos: android/, README.md
Fuera de alcance: Play Store listing, IPA unless time remains.
```

---

## US-16 · 📗 · 🟢 P3 · README product brief · ☐ Pendiente

**Prompt**
```
Contexto: README is still the Flutter template.

Tarea: Replace with short Spanish/English product brief: what LMB Plusur is,
Zona Sur scope, how to run, AR marker testing tips, link to CONSTITUTION /
WORK_ITEMS. No secrets.

Criterios de aceptación:
- Newcomer can run the app from README alone.
- Points to governance files.

Archivos: README.md
Fuera de alcance: marketing site.
```

---

# 🐛 BUGS

## BUG-01 · 🟡 P2 · AR mock always Guerreros / first team · ☐ Pendiente

**Prompt**
```
Contexto: ArViewScreen timer sets guerreros_oaxaca or first equipo. Wrong for
multi-marker grading.

Tarea: Do not “fix” in isolation if US-06 is next — prefer closing this by
implementing US-06. If US-06 slips, temporarily map demo detection to a
selectable marker id list instead of a single hardcode.

Criterios de aceptación:
- Non-demo path never forces a single team.
- Demo path labeled in UI.

Archivos: lib/screens/ar_view_screen.dart
Fuera de alcance: filter feature.
```

---

## Suggested sequence

1. US-01 → US-02 → US-03 → US-04 (quick wins on existing shell)
2. SP-01 → US-05 → US-06 → US-07 → US-08 (AR grading core)
3. US-11 → US-12 (video + filters grading core)
4. US-09 → US-10 → US-13 (depth / bonus)
5. US-14 → US-15 → US-16 (ship)

Human in parallel: print 3 markers, make/get 3 GLBs, gather baseball video URLs,
plan demo recording.
