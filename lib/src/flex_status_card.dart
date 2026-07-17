import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A pre-built card that shows the Flex logo, a line of body copy, and a CTA
/// that opens the Flex Checkout flow when tapped.
///
/// Configure the checkout lifecycle callbacks via [Flex.instance.checkout]
/// before adding this widget.
///
/// ```dart
/// FlexStatusCard()
/// ```
class FlexStatusCard extends StatelessWidget {
  /// Height of the card in logical pixels. The native card self-sizes to its
  /// content, but Flutter platform views need an explicit height; the default
  /// fits the standard copy at typical phone widths. Override if the card
  /// clips on narrow layouts.
  final double height;

  /// Whether the card is visible. Defaults to true.
  final bool visible;

  const FlexStatusCard({
    this.height = 210,
    this.visible = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const viewType = 'com.flex.checkout/status-card';

    const creationParams = <String, dynamic>{};

    // Forward touches to the native card. Without this, Flutter's gesture
    // arena wins by default and the native tap handler never fires.
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

    return Visibility(
      visible: visible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: SizedBox(height: height, child: nativeView),
    );
  }
}
