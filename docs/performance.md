# Performance notes (US-14)

Brief before/after for defense / explanatory video. Measured on code paths
and asset inventory (2026-09-09). Device frame timings still human-open.

## Before

| Path | Cost |
|---|---|
| Splash → main | Fixed **3 s** timer + full-res decode of `LMB_plusur.png` (1920×1080) into a 176 px circle. Poppins fetched on first paint via `google_fonts`. |
| Video + filter | `VideoPlayerController.addListener` → `setState` every tick rebuilt the **whole** stack, including `FilterEngine.aplicar` (blur / pixelado). Classic jank with desenfoque. |
| AR enter | Compiles **all** scored logos into the image DB (~2.3 MB markers). Águila ~795 KB, Diablos ~697 KB dominate. |
| AR VFX | 10 Filament baseball nodes + 36 sparks + 22 confetti; chrome `setState` rebuilt the camera `PlatformView` sibling. |
| JSON | `DataService` re-read `data.json` / `videos.json` / `ar_markers.json` on every screen open. |

Already fine before this pass: lazy video mount (one player), lazy GLB attach
on `ArLocked`, AR session `ValueNotifier`, disposals on splash/AR/video
controllers.

## After (this pass)

| Change | Effect |
|---|---|
| Splash waits on logo precache + Poppins + ~1.1 s brand beat (no 3 s idle) | Perceived load closer to real warm-up (~1–1.5 s typical). |
| `AppLogo` uses `cacheWidth` / `cacheHeight` from display size × DPR | Avoids decoding the full 1920×1080 bitmap for every logo widget. |
| Video chrome in `ListenableBuilder`; filter+`VideoPlayer` outside tick rebuilds | Blur/pixelado no longer rebuilt every frame. |
| Slightly softer blur sigmas (2.4 / 0.9) | Cheaper compositor path; look still readable. |
| VFX: **6** balls, **24** sparks, **14** confetti | Keeps baseball flavor under mid-tier Filament + paint budget. |
| AR camera surface kept outside session/action rebuild tree (`ValueKey`) | Action taps should not tear down the platform view. |
| `DataService` memoizes equipos / videos / marcadores | Repeat navigations skip JSON parse. |

## Intentionally not changed

- **Águila / Diablos marker files** — large, but re-encoding Águila previously
  dropped `arcoreimg` from 100 → 90. Do not recompress without re-scoring
  (`docs/ar-marker-guide.md`). Gate remains ≥ 75.
- Full font bundling (`GoogleFonts.config.allowRuntimeFetching = false`) —
  deferred; splash now waits on `pendingFonts` so first paint is warmer.
- Architecture rewrite, Unity, or dropping markers from the DB.

## Dispose checklist (verified in code)

- Splash: `AnimationController` disposed; no dangling Timer.
- AR: `_spin`, `_efectoDrive`, `_uiState`, session subscription, tracker
  `clearEffect` / `dispose`.
- Video: listener removed; `VideoPlayerController.dispose` on leave /
  widget dispose. Switching `_playingId` unmounts the previous player.

## Human follow-up (optional for the 15pt story)

1. Cold start: splash → main on physical Android; note wall time.
2. AR: enter scanner, lock one logo, toggle Celebración / Efecto a few times —
   session must stay up (also AR-07 device gate).
3. Archivo: play a clip, apply desenfoque then térmica — UI should stay smooth
   enough for demo.

## Rebuild reminder

After `flutter pub get`, re-run both plugin patches before a device install:

```powershell
powershell -ExecutionPolicy Bypass -File tools/patch_arcore_image_width.ps1
powershell -ExecutionPolicy Bypass -File tools/patch_filament_clips.ps1
```
