# LMB Plusur

Flutter AR fan app for **LMB Zona Sur** (10 Mexican baseball clubs). Scan club
logos for AR experiences, or pick a team manually. Video archive, trivia, and
simulated stats. No Unity, no backend API, no logins.

Governance (agents and humans): [`CONSTITUTION.md`](./CONSTITUTION.md),
[`AGENTS.md`](./AGENTS.md), [`WORK_ITEMS.md`](./WORK_ITEMS.md),
[`docs/agent-handoff.md`](./docs/agent-handoff.md).

## Requirements

- Flutter **3.47+** / Dart **3.13+**
- **JDK 17** for Android builds (`flutter config --jdk-dir=…` if `JAVA_HOME` points at an older JRE)
- Physical Android device with **Play Services for AR** for real marker tracking (`minSdk` 24)
- After every `flutter pub get`, re-apply the plugin patches (pub restores stock files):

```powershell
powershell -ExecutionPolicy Bypass -File tools/patch_arcore_image_width.ps1
powershell -ExecutionPolicy Bypass -File tools/patch_filament_clips.ps1
```

## Run (debug)

```powershell
flutter pub get
powershell -ExecutionPolicy Bypass -File tools/patch_arcore_image_width.ps1
powershell -ExecutionPolicy Bypass -File tools/patch_filament_clips.ps1
flutter run
```

Demo AR without a capable device / camera:

```powershell
flutter run --dart-define=LMB_AR_DEMO=true
```

## Build and install the APK (US-15)

Release builds currently use the **debug keystore** (fine for class demos; not
for Play Store). No minify/Proguard is enabled.

```powershell
flutter pub get
powershell -ExecutionPolicy Bypass -File tools/patch_arcore_image_width.ps1
powershell -ExecutionPolicy Bypass -File tools/patch_filament_clips.ps1
flutter build apk
```

Output:

`build/app/outputs/flutter-apk/app-release.apk`

### Install on a phone

1. Enable **Developer options** → **USB debugging** (or allow install from the file manager / browser).
2. Copy the APK to the phone, or use adb:

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

3. Open **LMB Plusur**. You should see the splash, then the main menu.
4. For AR: grant camera permission; install/update **Google Play Services for AR** if prompted. Print a scored logo at ≥ 15 cm matte (see `docs/ar-marker-guide.md`).

### Optional: your own release keystore

Create a keystore locally, add `android/key.properties` (git-ignored), and wire
a `signingConfigs.release` in `android/app/build.gradle.kts`. Do **not** commit
passwords or `.jks` / `.keystore` files.

## Marker tip

Scan targets are club logos that score ≥ 75 with `arcoreimg` — not substitute
cards. Do not re-encode the Águila crest or other “ship raw” markers without
re-scoring.
