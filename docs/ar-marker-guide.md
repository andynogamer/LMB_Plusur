# Marker guide — designing targets ARCore can actually track

**Status:** binding. Referenced by Constitution **Article VI** / **D-13**, **D-21**.
**Version:** 2.0 · 2026-09-07 (rewritten after measuring the real logo set)
**Audience:** the human authoring marker art, and any agent adding a marker.

---

## 1. Measured reality of the LMB logo set

AR attempt #1 assumed the club logos would work as tracking targets, never
measured them, and then spent 612 lines of Dart trying to compensate
([postmortem RC-1](./ar-postmortem.md#rc-1--the-tracking-targets-were-bare-team-logos-arcore-cannot-track-those)).

We have now measured them. Both columns are real `arcoreimg eval-img` output.

| Logo | Raw asset | After normalization (§3) | Verdict |
|---|---|---|---|
| `leones_yucatan` | 90 | **100** | ✅ excellent |
| `olmecas_tabasco` | 50 | **100** | ✅ excellent |
| `piratas_campeche` | 35 | **100** | ✅ excellent |
| `bravos_leon` | *no keypoints* | **90** | ✅ good |
| `tigres_quintana_roo` | **75** | 50 | ⚠️ use the **raw** asset |
| `guerreros_oaxaca` | 50 | 50 | ❌ too flat |
| `diablos_rojos` | 40 | 50 | ❌ too flat |
| `conspiradores_queretaro` | *no keypoints* | *no keypoints* | ❌ hopeless |
| `el_aguila_veracruz` | *no keypoints* | *no keypoints* | ❌ hopeless |
| `pericos_puebla` | *no keypoints* | *no keypoints* | ❌ hopeless |

Three conclusions that drive everything below:

1. **Logos are not uniformly unusable.** Four clear the ≥ 75 bar, which is more
   than the three the grading gate needs. No custom matcher, no ML classifier
   and no redesigned art are required for the happy path.
2. **The dominant defect was asset hygiene, not art.** Nine of ten logos were
   below ARCore's 300 × 300 minimum (mostly 256 × 256), and four were 8-bit
   indexed PNGs whose transparency flattened to **black**, erasing keypoints.
   Fixing just those two things turned one hard failure into a 90 and lifted a
   35 to a 100.
3. **Some logos genuinely cannot be tracked.** `el_aguila_veracruz` is close to
   a uniform red field; `conspiradores` and `pericos` are flat line art.
   `arcoreimg` cannot extract *any* keypoints from them. No amount of
   resampling changes that — they need a marker card (§5) or nothing.

### Why ARCore behaves this way

> ARCore uses computer vision to extract **grayscale** features from reference
> images… Avoid images that contain a large number of geometric features, or
> very few features (e.g. barcodes, QR codes, **logos and other line art**).
>
> Color information is not used.
>
> — [ARCore: Augmented Images](https://developers.google.com/ar/develop/augmented-images)

Colour is discarded. What survives is grayscale detail. That is why the
illustration-heavy crests (Leones, Olmecas, Piratas) score 100 while flat
two-colour marks score zero — and why a red logo on a red field is invisible to
the tracker even though it is obvious to you.

---

## 2. Ratified marker set (D-20)

Chosen from the passing logos, covering three distinct `tipo` values:

| Marker id | Logo | Score | `tipo` |
|---|---|---|---|
| `marcador_estadio_leones` | `leones_yucatan` | **100** | estadio |
| `marcador_jugador_olmecas` | `olmecas_tabasco` | **100** | jugador |
| `marcador_trofeo_piratas` | `piratas_campeche` | **100** | trofeo |
| `marcador_pelota_bravos` | `bravos_leon` | **90** | pelota (spare / 4th) |

> The three markers originally ratified in v2.0.0 — Diablos (50), Guerreros (50)
> and Pericos (*no keypoints*) — were the **worst** available choices. They were
> picked before anyone measured. `pericos_puebla` cannot produce a single
> keypoint, so that marker could never have worked. D-20 was amended on
> 2026-09-07 to the set above.

Keep `marcador_pelota_bravos` as a spare: if one of the three underperforms on
the physical print, swap it in rather than accepting a weak target.

---

## 3. Step 1 — normalize before you judge (D-21)

```powershell
powershell -ExecutionPolicy Bypass -File tools/normalize_markers.ps1
```

This flattens any alpha onto **white** (never black), upscales the short side to
512 px, and writes 24-bit PNG to `build/markers-normalized/`.

Then always re-score and compare:

```powershell
$env:ARCOREIMG = "$PWD\tools\bin\arcoreimg.exe"
powershell -ExecutionPolicy Bypass -File tools/score_markers.ps1 -MarkersDir build/markers-normalized
```

**Normalization is not automatically an improvement.**
`tigres_quintana_roo` went **75 → 50**: it was already 1000 × 1000, and
resampling softened the high-frequency detail that was earning its keypoints.
Keep whichever version of each logo scores higher, and record which one you
shipped.

---

## 4. Getting `arcoreimg`

The scorer needs Google's `arcoreimg`, which is not in this repo (it is 4.5 MB
and `tools/bin/` is git-ignored). Fetch it once:

```powershell
Invoke-WebRequest -UseBasicParsing `
  -Uri 'https://raw.githubusercontent.com/google-ar/arcore-android-sdk/master/tools/arcoreimg/windows/arcoreimg.exe' `
  -OutFile tools/bin/arcoreimg.exe
```

Or download the full [ARCore SDK for Android](https://github.com/google-ar/arcore-android-sdk)
and use `tools/arcoreimg/windows/arcoreimg.exe`. Point the scorer at it with
`$env:ARCOREIMG` or `-ArcoreImg`.

Exit codes: `0` all pass · `1` something scored under 75 · `2` tooling missing.

---

## 5. Step 2 (only if needed) — a marker card

Needed only for logos that cannot be rescued by §3 — today
`conspiradores_queretaro`, `el_aguila_veracruz`, `pericos_puebla`. **We do not
currently need any of these**, since four logos already pass. Do this only if a
specific club becomes a requirement.

A **marker card** keeps the club logo for the human while surrounding it with
composition the tracker can actually key on.

```
┌──────────────────────────────────────────────┐  ← 15 cm minimum, matte paper
│  ░▒▓ irregular high-contrast texture ▓▒░     │
│    ┌────────────────────────────────┐        │
│    │      CLUB LOGO (for humans)    │        │
│    └────────────────────────────────┘        │
│  EL ÁGUILA · ESTADIO          ▞▚▞ stitching  │
│  LMB PLUSUR · ZONA SUR            [▪▫▪] ID   │  ← optional code, §8
└──────────────────────────────────────────────┘
```

All four elements are required:

1. **The club logo**, for recognition by the fan. It contributes almost nothing
   to tracking — that is expected.
2. **Irregular, non-repeating, high-contrast texture** filling the background.
   This does the actual tracking work. Baseball-coherent sources: leather ball
   stitching, worn infield dirt, crowd grain, aged box-score newsprint.
3. **Asymmetric text at two sizes** — club name, subject, a date. Text is
   keypoint-dense and breaks rotational ambiguity.
4. **A deliberately asymmetric layout.** Symmetry causes pose ambiguity, so the
   model can snap to the wrong orientation.

Hard avoids:

| Avoid | Why |
|---|---|
| Repeating patterns, grids, polka dots, stripes | keypoints stop being unique |
| Large flat colour areas | no keypoints at all — this is the Águila failure |
| Logo alone on white | RC-1 |
| Heavy JPEG compression | interferes with feature extraction |
| Mirror-symmetric layouts | pose ambiguity |
| Gradients as the main texture | smooth = featureless |

Then score it exactly like any other reference image: **≥ 75 or redesign**. A
low score is never fixed in code.

---

## 6. Non-negotiable specs

### Digital reference image (`assets/markers/`)

| Spec | Requirement |
|---|---|
| Format | PNG or JPEG, 24-bit, **no alpha** |
| Resolution | ≥ 300 × 300 px (we target ≥ 512 short side). Higher does not improve tracking |
| `arcoreimg eval-img` | **≥ 75** — hard merge gate |
| Compression | light; avoid visible JPEG artifacts |
| Filename | `marcador_<tipo>_<equipo>.png`, stem **must** equal `Marcador.id` |

### Physical print

| Spec | Requirement |
|---|---|
| Size | ≥ 15 × 15 cm. A5 or larger is comfortable |
| Paper | **matte** — glossy reflections destroy tracking |
| Flatness | flat; not curved, folded or creased |
| Framing at scan time | must fill **≥ 25 %** of the camera frame to be detected |
| Lighting | even indoor light; avoid glare and deep shadow |
| Motion | hold reasonably still; motion blur blocks initial detection |

Record the printed width in metres as `anchoMetros` in `ar_markers.json` —
supplying real-world size measurably improves ARCore detection and pose.

---

## 7. Recorded scores

Update this table in the same commit as any marker change.

**Shipped in `assets/markers/`** (verified 2026-09-07, `score_markers.ps1`
exit 0):

| Marker id | Source logo | Variant | Size | Score | Printed width (m) | In active DB |
|---|---|---|---|---|---|---|
| `marcador_estadio_leones` | `leones_yucatan` | normalized | 512×512 | **100** | ⏳ _pending print_ | ✅ yes |
| `marcador_jugador_olmecas` | `olmecas_tabasco` | normalized | 512×512 | **100** | ⏳ _pending print_ | ✅ yes |
| `marcador_trofeo_piratas` | `piratas_campeche` | normalized | 512×512 | **100** | ⏳ _pending print_ | ✅ yes |
| `marcador_pelota_bravos` | `bravos_leon` | normalized | 533×512 | **90** | ⏳ _pending print_ | ➖ spare only |

All four are 24-bit PNG with no alpha. The spare is bundled and printable but
**must not** go in the active tracking database — the budget is three
([architecture §10](./ar-architecture.md#10-performance-budgets)); unused entries
cost CPU. Swap it in only if a shipped marker underperforms on paper.

**Not usable as direct targets** — recorded so nobody retries them:

| Logo | Best score | Note |
|---|---|---|
| `tigres_quintana_roo` | 75 (raw only) | usable if ever needed; **do not** normalize it |
| `guerreros_oaxaca` · `diablos_rojos` | 50 | too flat |
| `conspiradores` · `el_aguila` · `pericos` | *no keypoints* | needs a marker card (§5) or nothing |

A high score proves the **digital reference** is good. It does **not** prove the
**print** detects — that still requires the device acceptance run in
[`ar-architecture.md` §7](./ar-architecture.md#7-verification-strategy). Glossy
paper, uneven light, or framing below 25 % of the camera frame will still fail
regardless of a 100.

---

## 8. Distinguishability

Scoring ≥ 75 individually is necessary but not sufficient — three targets that
each score 100 but look alike to a grayscale matcher can still swap.

The ratified set is naturally well separated (a Maya-styled lion, an Olmec head,
a pirate motif), but confirm it empirically: the **wrong-club control row** in
the acceptance run must show **zero** false positives.

---

## 9. Adding a new marker — checklist

1. Run `tools/normalize_markers.ps1`, then `tools/score_markers.ps1`. Keep the
   higher-scoring variant.
2. If < 75, build a marker card (§5). Do not proceed until it scores ≥ 75.
3. Name it `marcador_<tipo>_<equipo>.png` in `assets/markers/`.
4. Record the score and shipped variant in §7.
5. Add the entry to `assets/ar_markers.json` — `id` **equal to the filename
   stem**, plus `equipoId`, `tipo`, `titulo`, `infoTexto`, `modelAsset`,
   `anchoMetros`, optional `videoUrl`, `animaciones`.
6. Add the GLB under `assets/models/<marcador_id>/` (≤ 4 MB, ≤ 50 k tris).
7. Print at ≥ 15 cm on matte paper.
8. Run the device acceptance table, both control rows included.

---

## 10. Optional: the ID code (contingency insurance)

Reserve roughly 2 × 2 cm in a corner for a QR/DataMatrix code encoding the
`Marcador.id` verbatim.

Unused while ARCore image tracking passes acceptance. If it does not, the
pre-authorised `HybridMarkerTracker`
([architecture §12](./ar-architecture.md#12-pre-authorised-contingency)) reads
that code for 100 %-deterministic identity while ARCore supplies pose from plane
detection — **without reprinting anything**.

Keep it small and cornered. The code itself is poor tracking material (ARCore
lists QR codes among things to avoid), which is exactly why the surrounding
texture does the tracking work.
