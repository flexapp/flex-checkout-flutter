import 'flex_sdk.dart';
import 'types.dart';

export 'flex_sdk.dart';

/// The main entry point for the Flex Checkout SDK.
///
/// Call [initialize] once during app startup to obtain a [FlexSDK] instance.
///
/// ```dart
/// final sdk = await Flex.initialize(FlexConfig(clientId: 'your-client-id'));
/// sdk.loadToken(() async => await MyAuth.getToken());
/// sdk.checkout(CheckoutConfig(
///   onClose: () { /* handle close */ },
///   onEvent: (event) { /* handle event */ },
/// ));
/// ```
class Flex {
  static FlexSDK? _instance;

  /// Returns the current [FlexSDK] instance.
  ///
  /// Throws a [StateError] if [initialize] has not been called, or if [FlexSDK.cleanup]
  /// has been called since the last `initialize`.
  static FlexSDK get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError('Flex.initialize() must be called first.');
    }
    return inst;
  }

  /// Initializes the Flex Checkout SDK.
  ///
  /// Safe to call multiple times: subsequent calls without an intervening
  /// [FlexSDK.cleanup] return the existing instance. After [FlexSDK.cleanup],
  /// the next call to `initialize` builds a fresh native SDK.
  ///
  /// - [config]: SDK configuration containing your client ID and target environment.
  static Future<FlexSDK> initialize(FlexConfig config) async {
    if (_instance != null) return _instance!;
    final sdk = await FlexSDK.create(config);
    _instance = sdk;
    return sdk;
  }

  /// Internal — called by [FlexSDK.cleanup] so the next `initialize` will
  /// actually rebuild the native SDK. Also used as a test hook.
  static void reset() {
    _instance = null;
  }

  Flex._();
}
