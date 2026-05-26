import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'types.dart';

/// A pre-built button that opens the Flex Checkout flow for split rent payments.
///
/// Tapping the button triggers the native checkout UI. Configure the checkout
/// lifecycle callbacks via [Flex.instance.checkout] before adding this widget.
///
/// ```dart
/// FlexSplitRentButton(
///   styles: ButtonStyles(height: 60),
///   variant: SplitRentButtonVariant.listItem,
/// )
/// ```
class FlexSplitRentButton extends StatelessWidget {
  /// Optional sizing overrides.
  final ButtonStyles? styles;

  /// Visual layout. Defaults to [SplitRentButtonVariant.defaultVariant].
  final SplitRentButtonVariant? variant;

  /// Corner-radius style for the [SplitRentButtonVariant.defaultVariant]
  /// variant. Defaults to [SplitRentButtonRadius.rounded]. Ignored for
  /// [SplitRentButtonVariant.listItem].
  final SplitRentButtonRadius? radius;

  /// Color scheme for the [SplitRentButtonVariant.defaultVariant] variant.
  /// Defaults to [SplitRentButtonColor.purple]. Ignored for
  /// [SplitRentButtonVariant.listItem].
  final SplitRentButtonColor? color;

  /// Whether the button is visible. Defaults to true.
  final bool visible;

  const FlexSplitRentButton({
    this.styles,
    this.variant,
    this.radius,
    this.color,
    this.visible = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const viewType = 'com.flex.checkout/split-rent-button';

    final creationParams = <String, dynamic>{
      if (styles?.height != null) 'height': styles!.height,
      if (variant != null) 'variant': variant!.value,
      if (radius != null) 'radius': radius!.value,
      if (color != null) 'color': color!.value,
    };

    // Forward touches to the native button. Without this, Flutter's gesture
    // arena wins by default and the native onClick never fires.
    final gestureRecognizers = <Factory<OneSequenceGestureRecognizer>>{
      Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
    };

    Widget nativeView;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      nativeView = UiKitView(
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: gestureRecognizers,
      );
    } else {
      nativeView = AndroidView(
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: gestureRecognizers,
      );
    }

    final double defaultHeight =
        variant == SplitRentButtonVariant.listItem ? 55 : 40;
    final double height = styles?.height ?? defaultHeight;
    return Visibility(
      visible: visible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: SizedBox(height: height, child: nativeView),
    );
  }
}
