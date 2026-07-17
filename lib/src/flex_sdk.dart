import 'dart:async';

import 'package:flutter/services.dart';

import 'flex.dart';
import 'types.dart';
import 'version.dart';

/// The Flex Checkout SDK instance. Obtain via [Flex.initialize].
class FlexSDK {
  static const _channel = MethodChannel('com.flex.checkout/methods');
  static const _eventChannel = EventChannel('com.flex.checkout/events');

  Future<String> Function()? _tokenLoader;
  CheckoutConfig? _checkoutConfig;
  StreamSubscription<dynamic>? _eventSubscription;

  FlexSDK._();

  static Future<FlexSDK> create(FlexConfig config) async {
    final sdk = FlexSDK._();
    _channel.setMethodCallHandler(sdk._handleNativeCall);
    // Pass the plugin's own version down so native analytics events are
    // attributed to `flutter` + this version rather than ios/android (SDK-1146).
    await _channel.invokeMethod<void>('initialize', {
      ...config.toMap(),
      'sdkVersion': kFlexCheckoutFlutterVersion,
    });
    return sdk;
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'tokenLoader') {
      final loader = _tokenLoader;
      if (loader == null) {
        throw PlatformException(
          code: 'NO_TOKEN_LOADER',
          message: 'loadToken() must be called before opening checkout.',
        );
      }
      return await loader();
    }
    return null;
  }

  /// Registers an async function that returns an authentication token.
  ///
  /// The SDK calls this loader when it needs a token to open the checkout flow.
  /// Must be called before the user taps [FlexSplitRentButton].
  void loadToken(Future<String> Function() loader) {
    _tokenLoader = loader;
  }

  /// Sets the checkout configuration and lifecycle callbacks.
  ///
  /// Call this before the user can trigger the checkout flow.
  void checkout(CheckoutConfig config) {
    _checkoutConfig = config;
    _channel.invokeMethod<void>('configureCheckout', {
      'interstitial': config.interstitial,
    });
    _setupEventListener();
  }

  void _setupEventListener() {
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        final map = event as Map<Object?, Object?>;
        switch (map['type'] as String?) {
          case 'open':
            _checkoutConfig?.onOpen?.call();
          case 'close':
            _checkoutConfig?.onClose?.call();
          case 'error':
            _checkoutConfig?.onError?.call(map['error'] as String? ?? '');
          case 'event':
            _checkoutConfig?.onEvent?.call(ModalEvent.fromMap(map));
        }
      },
      onError: (_) {},
    );
  }

  /// Programmatically opens the checkout flow.
  ///
  /// Call [loadToken] and [checkout] first. The native bottom sheet is
  /// presented on the current top view controller (iOS) / activity (Android).
  /// Most apps don't need this — [FlexSplitRentButton] taps trigger
  /// `openCheckout` internally. Use it only when you have a custom entry
  /// point.
  void openCheckout() {
    _channel.invokeMethod<void>('openCheckout');
  }

  /// Programmatically closes the checkout flow if it is currently open.
  void closeCheckout() {
    _channel.invokeMethod<void>('closeCheckout');
  }

  /// Logs an impression event indicating the Flex checkout widget was shown
  /// to the user.
  ///
  /// Call this when your checkout entry point (button, screen, etc.) becomes
  /// visible. The [data] map can include any additional context to attach to
  /// the event.
  void logImpression([Map<String, dynamic> data = const {}]) {
    _channel.invokeMethod<void>('logImpression', {'data': data});
  }

  /// Releases all SDK resources.
  ///
  /// Call this only when the user signs out of your app — it wipes the
  /// in-flight WebView state so the next user doesn't land into the
  /// previous user's session. Do **not** call this on every navigation
  /// away from your checkout screen; it would destroy the warm WebView
  /// and force a full re-load + re-onboarding the next time the user
  /// taps the button.
  ///
  /// After calling this, the next [Flex.initialize] rebuilds the native
  /// SDK from scratch.
  void cleanup() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _checkoutConfig = null;
    _tokenLoader = null;
    _channel.invokeMethod<void>('cleanup');
    // Clear the Dart-side singleton so the next call to Flex.initialize
    // actually creates a fresh FlexSDK rather than returning this stale one.
    Flex.reset();
  }
}
