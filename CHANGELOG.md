## 1.2.6

- Adopt Android SDK 1.5.5: checkout lifecycle fixes — orphaned sheets after
  process death now self-dismiss instead of hanging, reopening checkout after
  `cleanup()` no longer stalls on the loading sheet, and the warm-reopen token
  race (token flag flipped on resolution rather than actual WebView delivery)
  is fixed.

## 1.2.5

- Adopt Android SDK 1.5.4 and iOS SDK 1.4.2.

## 1.2.4

- Adopt Android SDK 1.5.3 and iOS SDK 1.4.1.

## 1.2.3

- Fix: migrate Android `kotlinOptions.jvmTarget` to `compilerOptions` DSL, required by Kotlin Gradle plugin shipped with Flutter 3.41.x.

## 1.2.2

- Fix: route `e2e` flag through `FlexDeveloperConfig` on both iOS and Android to match native SDK 1.4.0 / 1.5.x API.

## 1.2.1

- Adopt Android SDK 1.5.1.

## 1.2.0

- Adopt Android SDK 1.5.0 and iOS SDK 1.4.0.

## 1.1.0

- Move `e2e` into `FlexDeveloperConfig`; adopt Android SDK 1.4.1 and iOS SDK 1.3.1.

## 1.0.0

- Initial release.
