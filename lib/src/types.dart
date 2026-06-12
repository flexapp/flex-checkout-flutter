/// Deployment environment for the Flex Checkout SDK.
enum FlexEnvironment {
  dev,
  int,
  local,
  pi,
  prod,
  qa,
  stg;

  String get value => name;
}

/// Event types emitted during the checkout flow.
enum ModalEventType {
  onboardingCompleted,
  paymentCompleted;

  static ModalEventType fromRawValue(String value) {
    return switch (value) {
      'MODAL_ONBOARDING_COMPLETED' => ModalEventType.onboardingCompleted,
      'MODAL_PAYMENT_COMPLETED' => ModalEventType.paymentCompleted,
      _ => throw ArgumentError('Unknown ModalEventType: $value'),
    };
  }
}

/// Visual layout of [FlexSplitRentButton].
///
/// - [defaultVariant]: the standard pill / rounded purple Flex button.
/// - [listItem]: a card-style row with a purple logo box on the left, the
///   "Split into 2 payments" label, and a right-aligned chevron. Intended for
///   placement inside a list or menu.
/// - [logo]: a circular icon-only button, suited for grid UIs (e.g. a payment
///   method picker). Android 1.4.0+ / iOS 1.2.0+.
enum SplitRentButtonVariant {
  defaultVariant,
  listItem,
  logo;

  String get value => switch (this) {
        SplitRentButtonVariant.defaultVariant => 'default',
        SplitRentButtonVariant.listItem => 'list_item',
        SplitRentButtonVariant.logo => 'logo',
      };
}

/// Corner radius of the [SplitRentButtonVariant.defaultVariant] button.
///
/// Ignored for [SplitRentButtonVariant.listItem].
enum SplitRentButtonRadius {
  square,
  rounded,
  pill;

  String get value => name;
}

/// Color scheme of the [SplitRentButtonVariant.defaultVariant] button.
///
/// - [purple]: purple fill, white label and logo (the original style).
/// - [white]: white fill, purple border, purple label and logo.
///
/// Ignored for [SplitRentButtonVariant.listItem].
enum SplitRentButtonColor {
  purple,
  white;

  String get value => name;
}

/// Developer-only configuration options for the Flex Checkout SDK.
///
/// Pass an instance to [FlexConfig.developer] to opt in to debug behaviours.
/// All options default to `false`.
class FlexDeveloperConfig {
  /// End-to-end testing mode.
  final bool e2e;

  /// Enable verbose SDK logging. Only active in non-production environments.
  final bool logs;

  const FlexDeveloperConfig({
    this.e2e = false,
    this.logs = false,
  });
}

/// SDK initialization configuration.
class FlexConfig {
  /// Your Flex client ID.
  final String clientId;

  /// The target environment. Defaults to [FlexEnvironment.int].
  final FlexEnvironment environment;

  /// Enable custom component overrides (e.g. LD-gated split rent button label).
  /// Defaults to false.
  final bool customComponents;

  /// Developer-only configuration options (e2e mode, verbose logging, etc.).
  ///
  /// Leave `null` (the default) in production builds.
  final FlexDeveloperConfig? developer;

  const FlexConfig({
    required this.clientId,
    this.environment = FlexEnvironment.int,
    this.customComponents = false,
    this.developer,
  });

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'environment': environment.value,
        'e2e': developer?.e2e ?? false,
        'logs': developer?.logs ?? false,
        'customComponents': customComponents,
      };
}

/// Checkout lifecycle callbacks.
class CheckoutConfig {
  /// Show an interstitial loading screen while the checkout loads. Defaults to true.
  final bool interstitial;

  /// Called when the checkout modal is presented.
  final void Function()? onOpen;

  /// Called when the checkout modal is dismissed.
  final void Function()? onClose;

  /// Called when an error occurs during checkout.
  final void Function(String error)? onError;

  /// Called when a checkout event occurs (e.g. onboarding or payment completed).
  final void Function(ModalEvent event)? onEvent;

  const CheckoutConfig({
    this.interstitial = true,
    this.onOpen,
    this.onClose,
    this.onError,
    this.onEvent,
  });
}

/// Optional sizing for the [FlexSplitRentButton].
class ButtonStyles {
  /// Fixed height of the button in logical pixels.
  final double? height;

  const ButtonStyles({this.height});
}

/// Data payload included with a [ModalEvent].
class ModalEventData {
  /// Whether autopay was enabled during the checkout flow.
  final bool autopayEnabled;

  const ModalEventData({this.autopayEnabled = false});

  factory ModalEventData.fromMap(Map<Object?, Object?> map) {
    return ModalEventData(
      autopayEnabled: map['autopayEnabled'] as bool? ?? false,
    );
  }
}

/// An event emitted by the checkout flow.
class ModalEvent {
  final ModalEventType type;
  final ModalEventData data;

  const ModalEvent({required this.type, required this.data});

  factory ModalEvent.fromMap(Map<Object?, Object?> map) {
    return ModalEvent(
      type: ModalEventType.fromRawValue(map['eventType'] as String? ?? ''),
      data: ModalEventData.fromMap(map['data'] as Map<Object?, Object?>? ?? {}),
    );
  }
}
