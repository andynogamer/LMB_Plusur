# Postmortem — AR attempt #1 (`ar-have-too-many-errors`)

**Date:** 2026-09-07
**Branch under review:** `origin/ar-have-too-many-errors` (5 commits on top of `fresh-start`)
**Outcome:** abandoned. Work restarted from `69aa1ff` on branch `fresh-start`.
**Status of this document:** normative. Every rule in Constitution Article VI
traces back to a root cause here. Do not delete this file — it is the reason
the rules exist.

---

## What was attempted

| Commit | Message |
|---|---|
| `5399646` | feat/US-05 |
| `3a280ec` | feat: US-06 |
| `8b09283` | bug: compabilty with android device |
| `dc31ad0` | fix: logos were no detected |
| `002b33f` | just reference |

Net: **1,974 insertions across 23 files**, of which `lib/screens/ar_view_screen.dart`
grew by **+685 lines** and a new `lib/services/logo_matcher_service.dart`
contributed **612 lines**.

The intent was: point the camera at a team's logo → recognize which club it is →
show a 3D model and AR controls.

---

## Root causes

### RC-1 — The tracking targets were bare team logos. ARCore cannot track those.

This is the primary root cause. Everything else is a downstream symptom.

The reference images fed to tracking were the raw club logos in
`assets/images/team-logos/…`. Google's ARCore documentation states directly:

> Avoid images that contain a large number of geometric features, or very few
> features (e.g. barcodes, QR codes, **logos and other line art**) as this will
> result in poor detection and tracking performance.
>
> — [ARCore: Augmented Images](https://developers.google.com/ar/develop/augmented-images)

ARCore extracts **grayscale** feature keypoints. Colour is discarded entirely. A
club logo is flat colour fields plus line art, so after grayscale conversion
there are almost no unique keypoints left to match. `El Águila de Veracruz` is
close to a uniform red field — zero usable features.

Commit `dc31ad0 "fix: logos were no detected"` is this root cause surfacing. It
was not fixable in the matcher. The input was wrong.

#### Update 2026-09-07 — the real failure was that nobody measured

The logos were finally scored with `arcoreimg`. The result refines this root
cause in an important way:

| Logo | Raw | Normalized | |
|---|---|---|---|
| `leones_yucatan` | 90 | **100** | ✅ |
| `olmecas_tabasco` | 50 | **100** | ✅ |
| `piratas_campeche` | 35 | **100** | ✅ |
| `bravos_leon` | *no keypoints* | **90** | ✅ |
| `tigres_quintana_roo` | **75** | 50 | ⚠️ raw is better |
| `guerreros_oaxaca` | 50 | 50 | ❌ |
| `diablos_rojos` | 40 | 50 | ❌ |
| `conspiradores` · `el_aguila` · `pericos` | *no keypoints* | *no keypoints* | ❌ |

**Four logos clear the bar** — one more than grading requires. ARCore can track
the real club logos directly. The custom matcher was never necessary.

Worse, the dominant defect was plain asset hygiene, not art direction: nine of
ten logos sat below ARCore's 300 × 300 minimum (mostly 256 × 256), and four were
8-bit indexed PNGs whose transparency flattened to **black**, destroying the
keypoints. Flattening onto white and upscaling took `bravos_leon` from *total
failure* to **90**, and `piratas_campeche` from 35 to **100**.

So the true root cause is not "logos are unsuitable". It is:

> **A one-command measurement was available the whole time, and nobody ran it.**
> Two weeks of matcher tuning substituted for ten minutes of `arcoreimg`.

The three markers ratified in Constitution v2.0.0 — Diablos (50), Guerreros (50),
Pericos (*no keypoints*) — were likewise chosen without measuring, and were the
three worst options available. `pericos_puebla` could never have worked at all.

**Rules derived:**
- **Measure the target before writing any detection code.** A reference image
  is not a tracking target until `arcoreimg eval-img` says ≥ 75
  (Constitution **D-13**).
- **Normalize assets first** — alpha onto white, short side ≥ 512, 24-bit — and
  re-score, because normalization can also *lower* a score (**D-21**).
- A logo scoring ≥ 75 is a legitimate target; only unrescuable logos need a
  purpose-built **marker card**. See
  [`ar-marker-guide.md`](./ar-marker-guide.md).

### RC-2 — A hand-rolled computer-vision matcher became the production detector.

Because RC-1 made real tracking fail, the branch wrote its own image matcher in
Dart: `LogoMatcherService`, 612 lines combining an average hash, a dHash, a
12-bin hue histogram, a saturation ratio, an aspect ratio and an "edge energy"
metric into one weighted score:

```dart
var score = hashScore * 0.22 +
    shapeScore * 0.34 +
    hueScore   * 0.24 +
    aspectScore * 0.12 +
    sat * 0.05 +
    energy * 0.03;
```

…and then an accept gate made entirely of tuned constants:

```dart
if (score > 28) return false;
if (margin < 3) return false;
if (margin < 5 && score > 22) return false;
if (hue > 0.55) return false;
if (probe.edgeEnergy < 5 && catalog.edgeEnergy >= 10) return false;
if (catalog.satRatio >= 50 && probe.satRatio < 22) return false;
```

Three problems, each fatal on its own:

1. **Not invariant to anything that matters.** Perceptual hashes are not
   invariant to scale, rotation, perspective or illumination. A phone photo of a
   printed sheet is none of those things relative to the source PNG.
2. **Untunable.** Nine interacting magic numbers with no ground-truth dataset.
   Every threshold change fixes one club and breaks another. That is the
   "bunch of bugs" — it is a whack-a-mole surface by construction.
3. **Wrong place, wrong cost.** Six probe crops × ten catalog entries, decoding
   and resizing full frames with `package:image` in Dart, per scan.

The file's own doc comment admits the failure mode:

> …grayscale MAD collapses onto El Águila (a nearly flat red field).

That is `BUG-01` ("AR mock always detects Guerreros / first team") reappearing in
a new costume: a detector that is statistically biased toward one club regardless
of what the camera sees.

**Rule derived:** no hand-written CV in the production detection path. Identity
comes from the platform tracker as a deterministic string, never from a
similarity score. Constitution **D-14**, **D-15**.

### RC-3 — Three overlapping mechanisms all claimed to be "the AR feature".

The branch simultaneously carried:

| Mechanism | What it actually did |
|---|---|
| `ar_flutter_plugin_plus` | Real ARCore image tracking — **added as a dependency but never actually mounted as an `ARView`** |
| `LogoMatcherService` | Dart hash guess on a still camera frame |
| `model_viewer_plus` | A **WebView** running `<model-viewer>`, shown in a rounded card |

The spike document conceded the gap in writing:

> **This spike does not yet embed the full ARView** (avoids breaking CI hosts
> without ARCore).

So the shipped experience was a WebView 3D widget sitting next to a Dart hash
guess — with two independent sources of truth for "which marker was detected"
and a 3D renderer that is architecturally incapable of compositing onto the
camera feed. A WebView cannot be a layer in an AR scene graph.

**Rule derived:** exactly one production detector and one production AR
renderer, both behind a single facade. WebView 3D is allowed only on non-camera
screens. Constitution **D-12**, **D-16**.

### RC-4 — Native toolchain was mutated to satisfy transitive dependencies.

```kotlin
// permission_handler_android requires API 37; Flutter default is still 36.
compileSdk = 37
…
dependencies { implementation("com.google.ar:core:1.52.0") }
```

```properties
org.gradle.java.installations.auto-detect=true
org.gradle.java.installations.auto-download=true
```

```kotlin
id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
```

Four independent build-break vectors: an SDK level ahead of the Flutter stable
default, a **second** manual ARCore dependency racing the plugin's own
transitive version, and Gradle silently downloading a JDK. Commit
`8b09283 "bug: compabilty with android device"` is this root cause surfacing.

**Rule derived:** native config changes are their own reviewed work item with a
recorded reason and a rollback note. Never let a dependency pull the toolchain
forward silently. Constitution **D-17**.

### RC-5 — A global developer-experience regression to paper over a local symptom.

```kotlin
buildTypes {
    debug {
        // ARCore image tracking jitters when debuggable is true.
        isDebuggable = false
    }
}
```

Copied from a plugin README. This disables the debugger and breaks the
`flutter run` debug contract for **every** developer, on **every** feature,
permanently — to reduce jitter in one screen. Debugging the AR screen, the exact
thing that needed debugging most, became impossible.

**Rule derived:** the `debug` build type stays debuggable. Tracking-smoothness
work belongs in `profile`/`release`. Constitution **D-17**.

### RC-6 — Batch size removed any known-good state.

US-05, US-06 and US-07 plus two firefighting commits landed on one branch. No
individual slice was independently verifiable on a device. Once detection
misbehaved there was nothing to bisect to — the only options were "all of it" or
"none of it". "None of it" is what happened.

**Rule derived:** one slice per branch, each independently device-verifiable,
each with a stated rollback. Constitution **D-18**.

### RC-7 — The automated test validated the wrong thing.

The single test loaded a **bundled logo asset** and asserted the matcher returned
that logo's `equipoId`:

```bash
flutter test test/logo_matcher_service_test.dart
```

That compares an asset against itself through the same decode path. It passes
trivially and tells you nothing about a phone camera photographing a printed
sheet under room lighting. The test suite was green while the feature was
unusable — which is worse than having no test, because it manufactured
confidence.

**Rule derived:** recognition quality is proven by a **device acceptance run**
recorded in the work item, not by unit tests. Unit tests cover the state machine
and registry mapping against a `FakeArTracker`. Constitution **D-18**,
[`ar-architecture.md`](./ar-architecture.md) §7.

---

## Summary table

| # | Root cause | Prevented by |
|---|---|---|
| RC-1 | Tracking targets never measured (and were unnormalized) | D-13, D-21 + marker guide (`arcoreimg` ≥ 75 gate) |
| RC-2 | Hand-rolled CV with magic thresholds as detector | D-14, D-15 |
| RC-3 | Three competing AR mechanisms, WebView 3D as "AR" | D-12, D-16 |
| RC-4 | Toolchain mutated by transitive deps | D-17 |
| RC-5 | `isDebuggable = false` in debug | D-17 |
| RC-6 | Three work items in one unbisectable branch | D-18 |
| RC-7 | Tests that compare an asset to itself | D-18, architecture §7 |

---

## What was actually worth keeping

Not everything was wrong. Carry these forward:

- **`ImageDetectionGate`** (`lib/services/image_detection_gate.dart`) — requiring
  N consecutive identical detections before locking a scan is the correct
  debounce pattern, and it was written testably with an injectable clock. Reuse
  the idea; feed it deterministic tracker names instead of hash guesses.
- **`Marcador` model + `assets/ar_markers.json`** — the data shape
  (`id`, `equipoId`, `tipo`, `titulo`, `infoTexto`, `markerImage`, `modelAsset`,
  `videoUrl`, `animaciones`) is sound and data-driven per Article V.
- **The three-marker `tipo` scheme** — estadio / jugador / trofeo covering three
  distinct content types was the right idea. Only the *clubs* were wrong (they
  were picked unmeasured). D-20 now assigns those same `tipo` values to Leones,
  Olmecas and Piratas, which score 100.
- **`MarkerIdMapper`** — mapping tracker image name → `equipoId` in one place is
  right. It becomes the `MarkerRegistry` in the new architecture.
- **Styled AR overlay chrome** — the navy/`AppColors` overlay treatment in
  `ar_view_screen.dart` satisfies Article IX and is worth re-reading for reference.

---

## The one-line lesson

> Attempt #1 failed because it wrote code to compensate for an input it had
> never measured. **Measure the target first; then let the platform track it.**
>
> The measurement took ten minutes and showed four logos already work.
