# AI 3D prompts — three AR models

**Need exactly 3 GLBs.** One file per grading marker. The spare Bravos card
is printable only and does **not** need a model.

Replace the placeholder box at each path. Do not rename the file or the clips.

| Marker | File | Clips inside the same GLB |
|---|---|---|
| Estadio · Leones de Yucatán | `assets/models/marcador_estadio_leones/modelo.glb` | `idle`, `celebracion` |
| Jugador · Olmecas de Tabasco | `assets/models/marcador_jugador_olmecas/modelo.glb` | `idle`, `gesto` |
| Trofeo · Piratas de Campeche | `assets/models/marcador_trofeo_piratas/modelo.glb` | `idle`, `celebracion` |

## Technical brief (paste with every prompt)

```
Export one binary glTF file (.glb), not GLTF+separate bin, not FBX, not USDZ.

Limits: under 4 MB, under 50,000 triangles. Prefer under 20,000 triangles
and 1024 textures so a mid-tier Android phone stays cool.

Coordinate system: Y-up. Origin at the bottom center of the model so it sits
on a table, not floating and not buried. Real-world scale: about 10 to 12 cm
tall. This will be viewed on a 15 cm printed card through a phone camera.

No ground plane, no backdrop, no card, no text, no logo watermark.
Single object, centered. Clean topology. Bake textures into the GLB.

Include two animation clips in the SAME file. Clip names must be exactly
these strings, lowercase, no spaces:
- idle — seamless loop, 2 to 4 seconds
- <second clip named below> — 1.5 to 3 seconds, may play once

Do not add extra clips. Do not name them Idle, Celebrate, or Animation.
```

## 1. Parque Kukulcán — estadio

```
A small stylized baseball stadium, night game, Mexican Liga baseball, not soccer.

Compact ballpark: diamond, mound, two dugouts, low stands, outfield wall,
a few light towers. Green grass, brown dirt, gold and forest-green seats
and wall trim (Leones de Yucatán). Empty of spectators so the mesh stays light.
No team wordmark, no readable text.

Animation clip "idle": slow pulse of the stadium lights and a barely moving
flag on the center-field wall. Loop.

Animation clip "celebracion": the lights flare, the scoreboard glow pulses,
and a small burst of confetti rises over the diamond, then settles. One shot.

<paste the technical brief above>
```

## 2. El legado olmeca — jugador

```
A stylized baseball player, full body, standing on a circular base.
Classic Olmec-inspired headdress suggestion kept subtle: a baseball cap
with a strong brow, not a sculpture replica. Navy and orange uniform
(Olmecas de Tabasco). Bat resting on the shoulder. No readable numbers,
no sponsor logos, no face of a real person.

Neutral, proud stance. One figure only.

Animation clip "idle": breathing, slight weight shift, bat tip moving.
Loop. Seamless.

Animation clip "gesto": a clear baseball gesture — tip the cap with the free
hand, or point the bat toward the field. Reads in under 3 seconds. One shot,
returns to the idle pose at the end.

<paste the technical brief above>
```

## 3. Serie del Rey — trofeo

```
A baseball championship trophy, not a soccer cup. A gold cup with two handles
on a dark wooden or metal base, a baseball sitting in the cup or beside it,
a small laurel. Red and black accents (Piratas de Campeche). No readable
engraving.

Animation clip "idle": a slow gleam traveling across the gold metal, cup
almost still. Loop.

Animation clip "celebracion": the trophy lifts slightly, rotates a quarter
turn, and a short gold sparkle rises and fades. One shot.

<paste the technical brief above>
```

## After export

1. Overwrite `modelo.glb` in the matching folder. Keep the filename.
2. Confirm the file is under 4 MB.
3. In Blender or the exporter, check the clip list shows only `idle` and
   `celebracion` or `gesto`, spelled exactly as above.
4. Scan that marker in the app. The model should sit on the card, not under it.
   If it is huge or microscopic, the exporter used the wrong unit — re-export
   at 10–12 cm, do not scale it in Dart.
