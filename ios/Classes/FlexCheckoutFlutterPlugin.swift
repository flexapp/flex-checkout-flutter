import Flutter
import UIKit
import FlexCheckout

public class FlexCheckoutFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, @unchecked Sendable {

    private var channel: FlutterMethodChannel!
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.flex.checkout/methods",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.flex.checkout/events",
            binaryMessenger: registrar.messenger()
        )

        let instance = FlexCheckoutFlutterPlugin()
        instance.channel = channel

        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)

        registrar.register(
            FlexSplitRentButtonFactory(),
            withId: "com.flex.checkout/split-rent-button"
        )
    }

    // MARK: - FlutterPlugin

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Expected map", details: nil))
                return
            }
            handleInitialize(args, result: result)

        case "configureCheckout":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Expected map", details: nil))
                return
            }
            handleConfigureCheckout(args, result: result)

        case "openCheckout":
            Flex.instance.openCheckout()
            result(nil)

        case "closeCheckout":
            Flex.instance.closeCheckout()
            result(nil)

        case "logImpression":
            let data = (call.arguments as? [String: Any])?["data"] as? [String: Any] ?? [:]
            Flex.instance.logImpression(data: data)
            result(nil)

        case "cleanup":
            Flex.instance.cleanup()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Initialize

    private func handleInitialize(_ args: [String: Any], result: @escaping FlutterResult) {
        let clientId = args["clientId"] as? String ?? ""
        let envString = args["environment"] as? String ?? "int"
        let e2e = args["e2e"] as? Bool ?? false
        let logs = args["logs"] as? Bool ?? false
        let customComponents = args["customComponents"] as? Bool ?? false

        let environment = FlexEnvironment(rawValue: envString) ?? .int
        let config = FlexConfig(
            clientId: clientId,
            environment: environment,
            e2e: e2e,
            customComponents: customComponents,
            developer: logs ? FlexDeveloperConfig(logs: true) : nil
        )

        let sdk = Flex.initialize(config: config)

        // Register a token loader that calls back into Dart when a token is needed.
        sdk.loadToken { [weak self] in
            guard let self else { throw FlexError.emptyToken }
            return try await self.requestTokenFromDart()
        }

        result(nil)
    }

    private func requestTokenFromDart() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: FlexError.emptyToken)
                    return
                }
                self.channel.invokeMethod("tokenLoader", arguments: nil) { response in
                    if let token = response as? String, !token.isEmpty {
                        continuation.resume(returning: token)
                    } else {
                        continuation.resume(throwing: FlexError.emptyToken)
                    }
                }
            }
        }
    }

    // MARK: - Configure Checkout

    private func handleConfigureCheckout(_ args: [String: Any], result: @escaping FlutterResult) {
        let interstitial = args["interstitial"] as? Bool ?? true

        Flex.instance.checkout(CheckoutConfig(
            interstitial: interstitial,
            onClose: { [weak self] in
                self?.eventSink?(["type": "close"])
            },
            onError: { [weak self] error in
                self?.eventSink?(["type": "error", "error": error])
            },
            onEvent: { [weak self] event in
                self?.eventSink?([
                    "type": "event",
                    "eventType": event.type.rawValue,
                    "data": ["autopayEnabled": event.data.autopayEnabled],
                ])
            },
            onOpen: { [weak self] in
                self?.eventSink?(["type": "open"])
            }
        ))

        result(nil)
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
