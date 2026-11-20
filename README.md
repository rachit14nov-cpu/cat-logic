# Cat Logic

A calm star-battle puzzle by **Tinybit Labs**. Place one cat in every row, every column, and every coloured region. Cats cannot touch, not even on a corner. Boards run from 5×5 to 10×10.

UI text uses Inter, bundled under the SIL Open Font License (`assets/fonts/OFL.txt`).

The Android application id is `com.tinybitlabs.catlogic`. Change it in one place:

```
config/application_id.txt
```

Android Gradle reads that file for `namespace` and `applicationId`, and generates `MainActivity` from it. After an edit, refresh the iOS mirror:

```bash
dart run tool/apply_application_id.dart
```

## Requirements

- Flutter stable (this tree was built with 3.50 / Dart 3.14)
- Android SDK 36. Play requires target API 36 for new apps and updates as of 31 August 2026.

```bash
flutter pub get
```

## Levels

Campaign puzzles live in `assets/levels/levels.json`. The daily pool (400+ days from 1 January 2026, then it repeats) lives in `assets/levels/daily.json`. Both files are generated and committed.

Regenerate them deterministically:

```bash
dart run tool/generate_levels.dart
```

The tool prints a count for every size and difficulty. A short sample, without writing assets:

```bash
dart run tool/generate_levels.dart --smoke
```

Every kept puzzle is checked for one solution, orthogonal regions, and a full solve by the deduction engine.

## Tests

```bash
flutter analyze
flutter test
```

Core tests cover the solver, uniqueness, the region generator, each deduction technique (including the hint sentence), daily streaks, and ad pacing. `flutter test` also writes UI screenshots to `screenshots/`.

## Android builds

Debug:

```bash
flutter build apk --debug
```

Release reads `android/key.properties` when that file exists. It is gitignored, along with `*.jks`, `*.keystore`, `google-services.json`, and `.env`. Do not commit a keystore.

```
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=your-alias
storeFile=../upload-keystore.jks
```

`storeFile` is relative to the `android/` directory, or an absolute path. If `key.properties` is absent, the release build is signed with the debug key so it can still be produced:

```bash
flutter build appbundle --release
```

## Layout

- `lib/core` is plain Dart: regions, solver, deduction, hints, daily index, and the ad-pacing rules. No Flutter imports.
- `lib/game` is the play session (tap, double-tap, undo, auto-mark, check, hint).
- `lib/ui` is widgets only. There is no game engine.
- `lib/services` defines `AdService`, `IapService`, `AnalyticsService`, and `CloudSaveService` with no-op implementations. No AdMob, Play Billing, Firebase, or Play Games SDK is included.

Ad pacing, for a later SDK, is all remote-config keys with these defaults:

- no interstitial on levels 1–8, and never mid-puzzle
- then one after every 2nd completed level
- at most one interstitial per 90 seconds, and 20 per day
- rewarded placements: hint, extra heart, second daily attempt
- banners only on the menu and level select

Using a hint does not affect the daily streak.
