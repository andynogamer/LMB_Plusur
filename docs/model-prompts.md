# AI 3D prompts — full-project catalog (D-22)

Branch `full-project`. **20 GLBs.** Every Zona Sur club gets the same two
models. Only the colors and the crest change.

**On disk today:** a shared low-poly mesh family from
`tools/write_lowpoly_glbs.py` (vertex colors, no textures). Stadiums have
no clips. Players are an articulated biped (node TRS, not skinned) with
clips `idle` (weight shift + breath) and `gesto` (point the bat, return
to rest). Regenerate from the repo root with
`python tools/write_lowpoly_glbs.py` or `--players-only`. The prompts
below are the upgrade path if replacing those files with authored art.
Do not add scan targets to “cover” clubs.

This is not automatically 10 scan targets. The camera locks only logos that
score ≥ 75 (see `docs/ar-marker-guide.md` §7). Clubs without a passing logo
open these models from the team menu. Do not generate extra marker images,
and do not ask the tool to “make the logo trackable.”

| Club id | Stadium (no animation) | Player (`idle` + `gesto`) |
|---|---|---|
| `diablos_rojos` | `assets/models/diablos_rojos/estadio.glb` | `assets/models/diablos_rojos/jugador.glb` |
| `bravos_leon` | `assets/models/bravos_leon/estadio.glb` | `assets/models/bravos_leon/jugador.glb` |
| `conspiradores_queretaro` | `assets/models/conspiradores_queretaro/estadio.glb` | `assets/models/conspiradores_queretaro/jugador.glb` |
| `aguila_veracruz` | `assets/models/aguila_veracruz/estadio.glb` | `assets/models/aguila_veracruz/jugador.glb` |
| `guerreros_oaxaca` | `assets/models/guerreros_oaxaca/estadio.glb` | `assets/models/guerreros_oaxaca/jugador.glb` |
| `leones_yucatan` | `assets/models/leones_yucatan/estadio.glb` | `assets/models/leones_yucatan/jugador.glb` |
| `olmecas_tabasco` | `assets/models/olmecas_tabasco/estadio.glb` | `assets/models/olmecas_tabasco/jugador.glb` |
| `pericos_puebla` | `assets/models/pericos_puebla/estadio.glb` | `assets/models/pericos_puebla/jugador.glb` |
| `piratas_campeche` | `assets/models/piratas_campeche/estadio.glb` | `assets/models/piratas_campeche/jugador.glb` |
| `tigres_quintana_roo` | `assets/models/tigres_quintana_roo/estadio.glb` | `assets/models/tigres_quintana_roo/jugador.glb` |

## Shared technical brief

```
Export one binary glTF file (.glb). Not GLTF+bin, not FBX, not USDZ.

Limits: under 4 MB, under 50,000 triangles. Prefer under 20,000 triangles
and 1024 textures.

Y-up. Origin at the bottom center, sitting on the ground. About 10 to 12 cm
tall. No ground plane, no backdrop, no card, no readable text, no watermark.
One object, centered. Bake textures into the file.

Reuse the same stadium mesh for every club. Reuse the same player mesh for
every club. Change only the kit colors and a simple crest on the cap or wall.
```

## Stadium — generate once, recolor 10 times

No animation clips. If the tool forces a clip, do not export it.

```
A small stylized baseball stadium, night game, Mexican Liga baseball, not soccer.

Same building every time: diamond, mound, two dugouts, low stands, outfield
wall, a few light towers. Empty of spectators. No wordmark.

Team treatment for <CLUB>: seats, wall stripe, and a simple crest on the
center-field wall in <COLORS>.

No animation.

<paste the shared technical brief>
```

| Club | Colors |
|---|---|
| Diablos Rojos | red and black |
| Bravos de León | red and navy |
| Conspiradores de Querétaro | burgundy and black |
| El Águila de Veracruz | red and white |
| Guerreros de Oaxaca | burgundy and gold |
| Leones de Yucatán | forest green and gold |
| Olmecas de Tabasco | navy and orange |
| Pericos de Puebla | green and yellow |
| Piratas de Campeche | red and black |
| Tigres de Quintana Roo | navy and orange |

## Player — generate once, recolor 10 times

The only animated model. Two clips in the same file, names exact:

- `idle` — seamless loop, 2 to 4 seconds
- `gesto` — one shot, 1.5 to 3 seconds, returns to the idle pose

No other clips. Do not name them `Idle` or `Celebrate`.

```
A stylized baseball player, full body, standing on a small circular base.
Generic face, not a real person. One figure. Baseball cap, jersey, bat on
the shoulder. No readable number, no sponsor logos.

Team treatment for <CLUB>: jersey, cap, and a simple crest in <COLORS>.

Animation clip "idle": breathing and a slight weight shift. Loop.
Animation clip "gesto": tip the cap or point the bat toward the field, then
return to the idle pose.

<paste the shared technical brief>
```

Use the same color table as the stadium.

## After export

1. Save under the path in the table. Filename is `estadio.glb` or `jugador.glb`.
2. Confirm each file is under 4 MB.
3. On the player, the clip list is exactly `idle` and `gesto`.
4. The stadium has no clips.
5. If a model is huge or buried in the card, fix the export scale. Do not
   scale it in Dart.
