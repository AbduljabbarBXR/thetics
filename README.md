# Thetics

**Natural physique training, honest nutrition, real progress tracking.**

Thetics is a local-first Flutter app for lifters who want a lean, muscular,
athletic physique without fantasy timelines. It combines structured training
programs, set-by-set logging, calorie and macro tracking, body measurements,
BMI screening, body-weight trends and private progress photos in one dark,
focused interface.

No account. No cloud. No ads. No fake "natural" marketing.

---

## What is inside

### Training
- Five complete, repeatable programs:
  - **Heavy Duty** — high-intensity, low-volume HIT inspired by Mike Mentzer.
  - **4×4 2/2/1** — density and work capacity with controlled tempo.
  - **Foundation 5×5** — linear strength progression.
  - **Upper / Lower Recomp** — balanced four-day hypertrophy and recomposition.
  - **PPL Aesthetics** — six-day push/pull/legs with an aesthetic bias.
- 69-exercise library with images, muscles, equipment, cues and instructions.
- Program browser with day-by-day prescriptions, rest targets and notes.
- Live workout logger:
  - Pre-filled sets and target reps.
  - Weight and rep editing.
  - Set check-off and automatic rest timer.
  - Session notes, finish summary and estimated-1RM PR detection.
  - Active-session recovery if the app closes.
- Workout history, volume totals and personal-record board.

### Nutrition
- Curated per-100 g food database of whole foods and gym staples.
- Meal logging by breakfast, lunch, dinner and snacks.
- Custom foods and quick re-log of recent foods.
- Calorie ring, macro bars, fibre and water tracking.
- Mifflin–St Jeor calorie estimate with goal adjustment.
- Protein, carbohydrate and fat targets with optional manual overrides.
- Honest guidance on sustainable rates of gain and loss.

### Progress
- Body-weight trend chart with 30/90/180-day windows.
- Full measurement log: weight, body fat, neck, shoulders, chest, waist, hips,
  biceps, thighs and calves.
- BMI with healthy weight range, band context and frame estimate.
- Waist-to-height ratio.
- Private progress-photo grid with date, weight and notes.
- Strength PR board.
- Local JSON backup and restore.

### Foundations
- Flutter + Riverpod `AsyncNotifier` state.
- JSON persistence via `shared_preferences`.
- Dark carbon/volt-lime design system with Barlow Condensed + Manrope.
- Android, iOS and web targets.
- No backend, account system or telemetry.

---

## Screens

| Area | Purpose |
| --- | --- |
| Dashboard | Today's workout, calories, macros, weight and weekly volume |
| Training | Program catalog, program detail, exercise library, history |
| Active workout | Set logging, rest timer, notes, finish summary |
| Nutrition | Meals, food search, custom foods, water, targets |
| Progress | Weight, measurements, BMI, photos, PRs |
| Profile | Profile editing, targets, settings, backup, reset, about |

---

## Getting started

### Requirements
- Flutter 3.24 or newer (Dart 3.5+)
- Java 17 for Android builds
- Android SDK for building an APK locally

### Run
```bash
git clone https://github.com/AbduljabbarBXR/thetics.git
cd thetics
flutter pub get
flutter run
```

### Verify
```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

### Build an APK
```bash
flutter build apk --release
```

The universal APK is written to:

```text
build/app/outputs/flutter-apk/app-release.apk
```

> The checked-in build config signs release builds with the Android debug key so
> the APK can be sideloaded. For a Play Store release, create your own keystore
> and update `android/app/build.gradle.kts`. Never commit signing secrets.

### Build for web
```bash
flutter build web --release
```

---

## CI / GitHub Actions

`.github/workflows/build.yml` runs on pushes to `main`, pull requests, tags
matching `v*`, and manual dispatch. It:

1. Installs Flutter stable and Java 17.
2. Checks formatting, analysis and tests.
3. Builds a release APK and a web bundle.
4. Uploads `thetics-apk-<run-number>` (APK + SHA-256) and
   `thetics-web-<run-number>` as workflow artifacts.

Artifacts are available from the **Actions** tab of the repository and can be
downloaded through the GitHub API with a token that has `actions:read`.

---

## Project layout

```text
lib/
  app.dart                     Root app, boot state, theme mode
  main.dart                    Entry point and LocalStore bootstrap
  core/
    models/                    Persisted AppData and settings
    state/                     Riverpod controller and providers
    storage/                   shared_preferences adapter
    theme/                     Palette and typography
    utils/                     BMI, macros, dates, formatting
    widgets/                   Buttons, cards, charts, sheets, logo
    demo/                      Demo history generator
  features/
    onboarding/                Five-step profile and goal setup
    shell/                     Five-tab navigation
    dashboard/                 Daily overview
    training/                  Programs, exercises, logger, history
    nutrition/                 Meals, local foods, custom foods
    progress/                  Weight, measurements, BMI, photos
    profile/                   Profile, targets, settings, backup, about
assets/
  exercises/                   69 bundled exercise images
  fonts/                       Barlow Condensed, Manrope (OFL)
  images/                      Brand logo and wordmark
test/                          BMI, macro, catalog, data and boot tests
```

---

## Privacy and backup

Everything is stored on the device. The app has no analytics, account or server.
Progress photos are copied into the app's private documents directory and are
never uploaded.

The current backup flow copies a complete JSON snapshot to the clipboard from
**Profile → Data & privacy → Copy backup JSON**. Paste it into a private note or
password manager. Importing replaces the local dataset. Treat a backup like a
diary: it contains body measurements, weights and notes.

The planned AI food-photo feature is **not active** in this build. The model and
storage layers already allow optional image paths for future food entries; it
will remain opt-in if it ships.

---

## Honest limits

This app is educational, not medical advice. It does not diagnose or treat any
condition.

Natural muscle gain is slow. A good year for a trained lifter might be roughly
**2–4 kg of lean mass**; beginners can do better, advanced lifters often do
less. Social-media physiques frequently involve performance-enhancing drugs,
lighting, pumps, editing or all of the above. No program, app or supplement
changes that reality.

BMI is a population screening tool that cannot distinguish muscle from fat.
Body-fat formulas and smart scales are estimates. If you are under 18, pregnant,
managing a health condition, recovering from injury or have a history of
disordered eating, speak with a qualified clinician or dietitian before
following a new training or nutrition plan. If a number is damaging your mental
health, that matters more than the number.

---

## Credits

- Exercise images and reference descriptions:
  [free-exercise-db](https://github.com/yuhonas/free-exercise-db) by yuhonas,
  released under **The Unlicense**.
- **Barlow Condensed** — SIL Open Font License 1.1.
- **Manrope** — SIL Open Font License 1.1.

See [NOTICE.md](NOTICE.md) for full attribution. Thetics is an independent
project and is not affiliated with or endorsed by any coach, athlete or estate.

---

**Built for the long game.**
