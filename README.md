# flex_checkout_flutter

Flutter plugin for the [Flex](https://getflex.com) Checkout SDK. Wraps the native [iOS](https://github.com/flexapp/flex-checkout-ios) and [Android](https://github.com/flexapp/flex-checkout-android) libraries using Flutter platform channels.

---

## Requirements

| Platform | Minimum version |
|----------|----------------|
| iOS      | 13.0           |
| Android  | API 26 (Android 8.0) |
| Flutter  | 3.3.0          |
| Dart     | 3.0.0          |

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flex_checkout_flutter:
    git:
      url: https://github.com/flexapp/flex-checkout-flutter.git
      ref: 1.0.0
```

Then run:

```bash
flutter pub get
```

### Android: add the JitPack Maven repository

The native Flex Checkout Android SDK is distributed via [JitPack](https://jitpack.io). Add the JitPack repo to your project's `android/settings.gradle.kts` so Gradle can resolve it:

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}
```

Without this, your Android build will fail to resolve `com.github.flexapp:flex-checkout-android`.

### Android: use `FlutterFragmentActivity`

The native Android SDK renders checkout in a `BottomSheetDialogFragment`, which requires the host `Activity` to be a `FragmentActivity`. The Flutter default `FlutterActivity` is not one. Change your `MainActivity.kt` to:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

Without this, tapping the button will fire `onError("Requires a FragmentActivity context")`.

### Android: use a `Theme.MaterialComponents.*` theme

The SDK uses `MaterialButton`, `BottomSheetDialogFragment`, and AppCompat vector drawables. The host activity's theme must inherit from `Theme.MaterialComponents.*` — the Flutter Android template's default `@android:style/Theme.Light.NoTitleBar` won't work (the bottom-sheet header logo won't render and bottom insets will be wrong, cutting off the primary CTA).

In `android/app/src/main/res/values/styles.xml`:

```xml
<style name="LaunchTheme" parent="Theme.MaterialComponents.Light.NoActionBar">
    <item name="android:windowBackground">@drawable/launch_background</item>
</style>
<style name="NormalTheme" parent="Theme.MaterialComponents.Light.NoActionBar">
    <item name="android:windowBackground">?android:colorBackground</item>
</style>
```

---

## Usage

### 1. Initialize

Call `Flex.initialize()` once during app startup, before `runApp()`.

```dart
import 'package:flex_checkout_flutter/flex_checkout_flutter.dart';
import 'package:flutter/material.dart' hide Flex;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sdk = await Flex.initialize(
    FlexConfig(clientId: 'your-client-id'),
  );

  runApp(MyApp());
}
```

> **Note:** Flutter's widget library also exports a class named `Flex`. Add `hide Flex` to your `flutter/material.dart` import to avoid the ambiguity.

---

### 2. Register a token loader

Register an async function that returns a valid authentication token. The SDK calls this automatically when it needs a token to open checkout.

```dart
sdk.loadToken(() async {
  final response = await http.get(Uri.parse('https://your-api.com/flex-token'));
  return response.body; // return the raw token string
});
```

---

### 3. Configure checkout callbacks

```dart
sdk.checkout(CheckoutConfig(
  interstitial: true, // show loading screen while checkout loads (default: true)
  onOpen: () {
    print('Checkout opened');
  },
  onClose: () {
    print('Checkout closed');
  },
  onError: (String error) {
    print('Checkout error: $error');
  },
  onEvent: (ModalEvent event) {
    switch (event.type) {
      case ModalEventType.onboardingCompleted:
        print('Autopay enabled: ${event.data.autopayEnabled}');
      case ModalEventType.paymentCompleted:
        print('Payment completed');
    }
  },
));
```

---

### 4. Add the button

Place `FlexSplitRentButton` in your widget tree. Tapping it opens the checkout flow.

```dart
FlexSplitRentButton(
  styles: ButtonStyles(height: 52),
)
```

The button has two visual variants and several style options:

```dart
// White pill button
FlexSplitRentButton(
  radius: SplitRentButtonRadius.pill,
  color: SplitRentButtonColor.white,
)

// List-item style (card row with chevron)
FlexSplitRentButton(
  variant: SplitRentButtonVariant.listItem,
)
```

---

### Optional: Open checkout from a custom button

Most apps use [`FlexSplitRentButton`](#4-add-the-button), which opens the
checkout flow when tapped. If you need to drive the flow from your own UI,
call `openCheckout()` after `loadToken()` and `checkout()` have been
configured.

```dart
sdk.openCheckout();
```

---

### Optional: Close checkout programmatically

```dart
sdk.closeCheckout();
```

---

### Optional: Log an impression

Call `logImpression()` when your Flex checkout entry point becomes visible. Useful for tracking placement performance.

```dart
sdk.logImpression({'screen': 'home'});
```

---

### Lifecycle

User state (form input, scroll position, partial flow progress) is preserved across opens — if a user starts onboarding, closes the sheet, and reopens, they resume right where they left off. The native WebView is pre-warmed automatically when you call `Flex.initialize`, so the first `openCheckout` is fast on both platforms.

### Cleanup

Call `cleanup()` **only when the user signs out of your app.** The WebView retains the previous user's in-flight UI state, so without `cleanup` on sign-out the next user would land into the previous user's session.

```dart
void signOut() {
  Flex.instance.cleanup();
  // ...your sign-out logic
}
```

After `cleanup`, the next `Flex.initialize` rebuilds the native SDK from scratch.

> **Do not** call `cleanup` from a screen's `dispose()` or whenever the user navigates away from your checkout screen. That destroys the warm WebView every time and the user loses any in-progress onboarding state on every re-entry. For most apps the sign-out hook is the only place `cleanup` is needed.

---

## Configuration reference

### `FlexConfig`

| Parameter     | Type              | Default             | Description                        |
|---------------|-------------------|---------------------|------------------------------------|
| `clientId`    | `String`          | required            | Your Flex client ID                |
| `environment` | `FlexEnvironment` | `FlexEnvironment.int` | Target environment               |
| `logs`        | `bool`            | `false`             | Verbose logging (Android only; iOS auto-disables logs in `prod`) |

### `FlexEnvironment`

| Value  | Description                                  |
|--------|----------------------------------------------|
| `int`  | Integration / sandbox environment (default)  |
| `prod` | Production environment                       |

### `CheckoutConfig`

| Parameter     | Type                          | Default | Description                              |
|---------------|-------------------------------|---------|------------------------------------------|
| `interstitial`| `bool`                        | `true`  | Show loading screen while checkout loads |
| `onOpen`      | `void Function()`             | —       | Checkout modal presented                 |
| `onClose`     | `void Function()`             | —       | Checkout modal dismissed                 |
| `onError`     | `void Function(String)`       | —       | Error during checkout                    |
| `onEvent`     | `void Function(ModalEvent)`   | —       | Checkout event fired                     |

### `FlexSplitRentButton`

| Parameter | Type                          | Default                              | Description                          |
|-----------|-------------------------------|--------------------------------------|--------------------------------------|
| `styles`  | `ButtonStyles?`               | —                                    | Optional sizing overrides            |
| `variant` | `SplitRentButtonVariant?`     | `SplitRentButtonVariant.defaultVariant` | Visual layout                    |
| `radius`  | `SplitRentButtonRadius?`      | `SplitRentButtonRadius.rounded`      | Corner style (default variant only)  |
| `color`   | `SplitRentButtonColor?`       | `SplitRentButtonColor.purple`        | Color scheme (default variant only)  |
| `visible` | `bool`                        | `true`                               | Whether the button is visible        |

### `ButtonStyles`

| Parameter | Type      | Description                          |
|-----------|-----------|--------------------------------------|
| `height`  | `double?` | Fixed height in logical pixels       |

### `SplitRentButtonVariant`

| Value             | Description                                                      |
|-------------------|------------------------------------------------------------------|
| `defaultVariant`  | The original pill / rounded purple Flex button                   |
| `listItem`        | Card-style row with logo box, label and chevron                  |

> iOS 1.2.0 also has a `.logo` variant. It's intentionally not exposed on Flutter until Android has parity — exposing it now would crash Android.

### `SplitRentButtonRadius`

`square` · `rounded` · `pill` — ignored for the `listItem` variant.

### `SplitRentButtonColor`

`purple` · `white` — ignored for the `listItem` variant.

---

## Complete example

```dart
import 'package:flex_checkout_flutter/flex_checkout_flutter.dart';
import 'package:flutter/material.dart' hide Flex;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sdk = await Flex.initialize(
    FlexConfig(
      clientId: 'your-client-id',
      environment: FlexEnvironment.prod,
    ),
  );

  sdk.loadToken(() async {
    // Fetch from your backend
    return await MyAuthService.getFlexToken();
  });

  sdk.checkout(CheckoutConfig(
    onClose: () => print('closed'),
    onEvent: (event) => print('event: ${event.type}'),
  ));

  runApp(const MyApp());
}

// In your widget:
const FlexSplitRentButton(
  styles: ButtonStyles(height: 52),
)
```

