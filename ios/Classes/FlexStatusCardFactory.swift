import Flutter
import UIKit
import FlexCheckout

class FlexStatusCardFactory: NSObject, FlutterPlatformViewFactory {

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FlexStatusCardNativeView(frame: frame)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

private class FlexStatusCardNativeView: NSObject, FlutterPlatformView {

    private let cardView: FlexStatusCardView

    init(frame: CGRect) {
        self.cardView = FlexStatusCardView(config: StatusCardConfig())
        self.cardView.frame = frame
        self.cardView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        super.init()
    }

    func view() -> UIView {
        return cardView
    }
}
