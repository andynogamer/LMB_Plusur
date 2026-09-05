# SP-01 ? Flutter-native AR spike

**Date:** 2026-09-04  
**Decision (R-01):** Use **`ar_flutter_plugin_plus`** for image-marker AR
(ARCore / ARKit), with an offline **`LogoMatcherService`** (average-hash)
against `assets/images/team-logos/` as catalog proof + camera fallback.
**Unity stays rejected (D-01).**

## Options compared

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **A. `ar_flutter_plugin_plus`** | Image tracking API, GLTF/GLB nodes, Android+iOS, Dart-facing | Native plugin quirks; Android prefers `debuggable false` for smooth tracking; heavier APK | **Chosen** |
| **B. Camera + hash/OpenCV only** | Pure Dart possible; easy for agents/tests | No real 6-DoF anchor on the logo; weaker ?AR? for grading | Fallback / tests |
| **C. Unity + `flutter_unity_widget`** | Strong VFX | Dual toolchain; poor AI-agent fit | Rejected (D-01) |
| **D. `augen` / other young plugins** | Modern APIs | Less battle-tested for this course timeline | Watch later |

## Chosen architecture

```
Flutter UI (overlays, trivia, stats)
        ?
        ?
ArSessionFacade
   ?? ar_flutter_plugin_plus  ? marker pose + 3D model node
   ?? LogoMatcherService      ? asset/camera frame ? equipoId
        ?
        ?
AppAssets.teamLogoById  (10 Zona Sur logos you added)
```

## Logos now in repo (D-04)

All 10 clubs have marker images under `assets/images/team-logos/?`, mapped in
`lib/theme/app_assets.dart` to stable `Equipo.id` keys.

Print these PNGs/JPGs at good size/contrast for physical scanning. Prefer
the highest-contrast logo as the first 3 grading markers (see US-05 / R-02).

## Android demo path

1. Device/emulator with **Google Play Services for AR** (ARCore). Physical
   device recommended for image tracking.
2. In a follow-up item (US-06), add dependency:
   `flutter pub add ar_flutter_plugin_plus`
3. Android:
   - `minSdk` ? 24
   - Camera permission in `AndroidManifest.xml`
   - Release/profile with `debuggable false` if tracking jitters
4. Pass logo asset paths from `AppAssets.teamLogoById` into
   `trackingImagePaths` on `ARSessionManager.onInitialize`.
5. On `onImageDetected`, map image name ? `equipoId` ? show Flutter overlay
   + optional GLB node.

**This spike does not yet embed the full ARView** (avoids breaking CI hosts
without ARCore). It **does** prove catalog recognition:

```bash
flutter test test/logo_matcher_service_test.dart
```

That test loads a bundled logo and asserts `LogoMatcherService` returns the
correct `equipoId`.

## iOS notes

Keep the iOS project healthy (`NSCameraUsageDescription`). Full IPA polish is
later; primary testing remains Android (D-02).

## Next work items

- **US-05** ? marcadores data model (?3) pointing at these logo paths + 3D assets
- **US-06** ? wire `ar_flutter_plugin_plus` into `ArViewScreen`, remove silent demo
- **US-07 / US-08** ? styled controls + ?2 actions on the AR window
