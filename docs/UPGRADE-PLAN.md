# Upgrade Plan — Devhub Mobile

## Current state

Score: 7.5/10 — developer text tools with lossless JSON formatting, unicode-aware case conversion, a11y guideline tests and fail-closed signing; no JWT/UUID tools, icon or E2E flow yet.

## Backlog

### P0
- None open. (Release signing now fails closed without `android/key.properties`.)

### P1
- Add JWT decode (header/payload only, no verification) and UUID generation tools.
- Replace the template launcher icon with a real app icon (the application ID `com.bookchaowalit.*` is already set).
- Add a Maestro smoke flow for the main journey.
- Add a CI job that builds a signed release bundle from repository secrets (keystore decoded at runtime, never committed).

### P2
- Tablet layout (NavigationRail).
- Localisation (Thai/English) for UI strings.

## Done in this pass (pass 3)

- Bug fix (data corruption): JSON format/minify decoded and re-encoded the input, so `12345678901234567890` became `12345678901234567000.0`, `1e2` became `100.0`, `1.50` became `1.5` and `é` escapes were rewritten. New `reformatJson` validates with `jsonDecode` but only rewrites whitespace between tokens, copying token text verbatim.
- Bug fix: case conversion split on `[^A-Za-z0-9]`, so `café au lait` became `caf_au_lait` and Thai words vanished entirely. Words are now split on Unicode letters/marks/digits.
- Edge-case unit tests: number/escape preservation, structural characters inside strings, empty containers, scalars, trailing garbage, format-then-decode equality, accented/Thai/emoji case conversion, Base64 (empty, newlines, non-UTF-8 bytes), URL decode (`%`, `+`, unicode round trip).
- Accessibility: output is a labelled live region ("Output"/"Error"). Widget tests: invalid input disables copy, a11y guidelines (tap target, labels, contrast), 200% text scale.
- The 200% text-scale widget test now runs at a 360 px phone width (it previously used the 800 px default test surface); no overflow found.

## Done in pass 2

- Release builds no longer sign with the debug key: `android/app/build.gradle.kts` reads the ignored `android/key.properties` and a Gradle guard fails any release assemble/bundle without it (pattern from `bookchaowalit-goal-tracker-mobile`). Root `.gitignore` also ignores `key.properties`, `*.jks`, `*.keystore`; README documents the setup. Not build-verified here (no Android SDK/Gradle in this environment).


## Done in pass 1

- Replaced the Expo/npm CI (which could never fail) with fail-closed Flutter CI: `dart format` check, `flutter analyze`, `flutter test`, debug APK on `main`.
- Implemented the core feature (everyday developer text tools in one place) with pure-Dart logic in `lib/logic/`.
- Replaced placeholder Explore/Profile tabs with an About screen describing features and privacy.
- Added unit tests for the logic and widget tests for the main journey.
- Removed unused `go_router` / `flutter_riverpod` dependencies; README now matches the code.
