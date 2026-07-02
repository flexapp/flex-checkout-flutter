## 1.2.4

- Attribute analytics events to `flutter`: the plugin now passes `sdk_platform: flutter` and its own package version as `sdk_version` down into both native cores at init (SDK-1146).
- Adopt iOS SDK 1.4.1 and Android SDK 1.5.2 (expose the wrapper-attribution init API).

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
