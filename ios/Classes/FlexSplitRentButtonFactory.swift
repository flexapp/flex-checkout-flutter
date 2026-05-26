import Flutter
import UIKit
import FlexCheckout

class FlexSplitRentButtonFactory: NSObject, FlutterPlatformViewFactory {

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let params = args as? [String: Any] ?? [:]
        return FlexSplitRentButtonNativeView(frame: frame, params: params)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

private class FlexSplitRentButtonNativeView: NSObject, FlutterPlatformView {

    private let buttonView: FlexSplitRentButtonView

    init(frame: CGRect, params: [String: Any]) {
        let height = params["height"] as? CGFloat
        let styles = height.map { ButtonStyles(height: $0) }
        let variant = (params["variant"] as? String).flatMap { SplitRentButtonVariant(rawValue: $0) }
        let radius = (params["radius"] as? String).flatMap { SplitRentButtonRadius(rawValue: $0) }
        let color = (params["color"] as? String).flatMap { SplitRentButtonColor(rawValue: $0) }
        let config = SplitRentButtonConfig(
            styles: styles,
            variant: variant,
            radius: radius,
            color: color
        )

        self.buttonView = FlexSplitRentButtonView(config: config)
        self.buttonView.frame = frame
        self.buttonView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        super.init()
    }

    func view() -> UIView {
        return buttonView
    }
}
