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

Campaign and daily puzzles are gzipped nibble packs:

- `assets/levels/campaign.bin.gz`
- `assets/levels/daily.bin.gz`

The app ungrips them at startup. The daily pool starts on 1 January 2026 and then repeats. Regenerate with:

```bash
dart run tool/generate_levels.dart
```

`dart run tool/generate_levels.dart --smoke` prints a short sample and does not write assets.

## Play

Story puzzles start with 3 hearts and a wallet of 3 hints. The first one opens with a short tutorial. Leaving a puzzle saves the board. A check that finds a broken placement spends one heart. An unfinished board does not. A rewarded ad gives one heart back, up to 3. Hints spend the wallet first, then offer an optional ad. Daily puzzles do not use hearts. The first play of a day is free; playing again that day asks for a rewarded ad. A hint never changes the streak.

Remove-ads turns off banners and interstitial breaks. Rewarded ads stay optional.

## Tests

```bash
flutter analyze
flutter test
```

## Android builds

Debug APKs always use Google's sample ad units. Release uses the live AdMob ids.

```bash
flutter build apk --debug
flutter build appbundle --release --target-platform android-arm64 --obfuscate --split-debug-info=build/symbols
```

The release bundle is arm64-only, with R8, resource shrinking, and Dart symbols kept out of the artifact (`build/symbols`, gitignored). Play still embeds native symbol tables and the R8 map in the AAB for crash reports. Those files are not downloaded onto phones. On this tree the AAB file is about 23 MB and the arm64 base module that a device downloads is about 10.8 MB.

Release signing reads `android/key.properties` when it exists. It is gitignored, along with `*.jks`, `*.keystore`, `google-services.json`, and `.env`.

```
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=your-alias
storeFile=../upload-keystore.jks
```

`storeFile` is relative to `android/`, or absolute. With no `key.properties`, release is signed with the debug key.

## Firebase

The app runs with Firebase turned off until `android/app/google-services.json` is present. That file is gitignored.

1. Create a Firebase project and add an Android app with package `com.tinybitlabs.catlogic`.
2. Download `google-services.json` into `android/app/`.
3. Rebuild. Gradle applies the Google services and Crashlytics plugins only when that file exists.

Analytics then records `level_start`, `level_complete`, `hint_used`, `daily_complete`, `ad_impression`, `ad_reward`, and `purchase`. Crashlytics records fatal Flutter and platform errors. Remote Config can override:

| Key | Default |
| --- | --- |
| `ads.interstitial.minLevel` | 9 |
| `ads.interstitial.everyCompleted` | 2 |
| `ads.interstitial.minIntervalMs` | 90000 |
| `ads.interstitial.dailyCap` | 20 |
| `ads.banner.surfaces` | `menu,levelSelect` |
| `ads.rewarded` | `hint,extraHeart,secondDailyAttempt` |

Until a fetch succeeds, those defaults are used. Every ad request is marked not child-directed (`tagForChildDirectedTreatment` and `tagForUnderAgeOfConsent` are false), with a max content rating of PG for a 13+ audience. Compile SDK and target SDK are 36. The UMP consent form runs before any ad load. Banners, interstitials, and rewarded hints stay off through campaign puzzle 8. After that, banners are only on the menu and level select, and an interstitial can appear between puzzles (after 10, 12, 14, and so on), never during one. Rewarded hints stay optional. Settings links the privacy policy, the data-deletion page, and support@tinybitlabs.co.

The first story puzzle shows a three-step tutorial once. Leaving a campaign puzzle saves the board, the clock, and the hearts, and Home offers Continue. Target API is 36, which is what Play requires for phone and tablet submissions after the 1 November 2026 extension.

## Play Console products

Create these in Play Console. Prices are the intended ones. The app shows Play's localized price when the product is available.

| Product id | Type | Price | Grants |
| --- | --- | --- | --- |
| `remove_ads` | Non-consumable | $4.99 | No banners or interstitial breaks. Rewarded ads stay optional. |
| `hints_small` | Consumable | $0.99 | 5 hints |
| `hints_medium` | Consumable | $2.49 | 15 hints |
| `hints_large` | Consumable | $4.99 | 40 hints |
| `starter_bundle` | Non-consumable | $2.99 | Remove ads, plus 10 hints the first time it is granted |

## Play Games cloud save

Cloud save stays off until `config/play_games_app_id.txt` contains the Play Games app id (the numeric id from Play Console). Then add this inside `<application>` in `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.games.APP_ID"
    android:value="YOUR_NUMERIC_APP_ID" />
```

Saved games must be enabled for the Play Games project. The snapshot name is `cat_logic_progress`. It stores progress, streaks, the hint wallet, and whether ads were removed.

## Layout

- `lib/core` is plain Dart: puzzles, the solver, hints, the shop rules, and ad pacing.
- `lib/game` is the board session, including hearts.
- `lib/services` talks to AdMob, Play Billing, and Play Games, and no-ops when those services are not configured.
- `lib/firebase` starts Analytics, Crashlytics, and Remote Config only after `Firebase.initializeApp` succeeds.
