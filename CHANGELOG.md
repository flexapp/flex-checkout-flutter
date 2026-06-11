## 1.1.0

- Bump Android SDK to 1.4.1, iOS SDK to 1.3.1
- Add `customComponents` to `FlexConfig` — enables LD-gated component overrides (e.g. split rent button label)
- Add `SplitRentButtonVariant.logo` — circular icon-only button, now available on both Android and iOS
- `FlexConfig.logs` now routes through `FlexDeveloperConfig` internally on both platforms; Dart API unchanged
- External links now open in Chrome Custom Tab (Android) / SFSafariViewController (iOS) instead of in-WebView navigation

## 1.0.0

- Initial release
