package com.flex.checkout.flutter

import android.app.Activity
import android.content.Context
import com.flex.checkout.Flex
import com.flex.checkout.configuration.CheckoutConfig
import com.flex.checkout.configuration.FlexConfig
import com.flex.checkout.types.FlexEnvironment
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMessageCodec
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class FlexCheckoutFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    EventChannel.StreamHandler {

    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context
    private var activity: Activity? = null
    private var eventSink: EventChannel.EventSink? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // Track warmup state so we can fire it once both `Flex.initialize` has
    // been called AND an Activity is attached — iOS auto-warms on initialize,
    // but Android's native warmup() requires a Context; we auto-call it here
    // so partners don't have to. Reset on cleanup so the next initialize
    // warms the rebuilt SDK.
    private var sdkInitialized = false
    private var warmupTriggered = false

    // MARK: - FlutterPlugin

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext

        channel = MethodChannel(binding.binaryMessenger, "com.flex.checkout/methods")
        channel.setMethodCallHandler(this)

        val eventChannel = EventChannel(binding.binaryMessenger, "com.flex.checkout/events")
        eventChannel.setStreamHandler(this)

        binding.platformViewRegistry.registerViewFactory(
            "com.flex.checkout/split-rent-button",
            FlexSplitRentButtonFactory { activity }
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    // MARK: - ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        maybeWarmup()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        // Don't re-warmup on config-change reattach — the WebView is already
        // warm from the original attach. warmupTriggered keeps that idempotent
        // even if maybeWarmup() were called here.
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    /**
     * Warm the native WebView once both the SDK is initialized AND an Activity
     * is attached. Mirrors iOS's auto-warm on `Flex.initialize`.
     */
    private fun maybeWarmup() {
        if (warmupTriggered) return
        if (!sdkInitialized) return
        val act = activity ?: return
        Flex.instance.warmup(act)
        warmupTriggered = true
    }

    // MARK: - MethodCallHandler

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val args = call.arguments as? Map<*, *> ?: run {
                    result.error("INVALID_ARGS", "Expected map", null)
                    return
                }
                handleInitialize(args, result)
            }
            "configureCheckout" -> {
                val args = call.arguments as? Map<*, *> ?: run {
                    result.error("INVALID_ARGS", "Expected map", null)
                    return
                }
                handleConfigureCheckout(args, result)
            }
            "openCheckout" -> {
                val act = activity
                if (act == null) {
                    result.error(
                        "NO_ACTIVITY",
                        "openCheckout requires the plugin to be attached to an Activity.",
                        null,
                    )
                } else {
                    Flex.instance.openCheckout(act)
                    result.success(null)
                }
            }
            "closeCheckout" -> {
                Flex.instance.closeCheckout()
                result.success(null)
            }
            "logImpression" -> {
                @Suppress("UNCHECKED_CAST")
                val data = (call.arguments as? Map<*, *>)?.get("data") as? Map<String, Any> ?: emptyMap()
                Flex.instance.logImpression(data)
                result.success(null)
            }
            "cleanup" -> {
                Flex.instance.cleanup()
                // Reset warmup state so the next initialize re-warms the
                // rebuilt SDK.
                sdkInitialized = false
                warmupTriggered = false
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // MARK: - Initialize

    private fun handleInitialize(args: Map<*, *>, result: Result) {
        val clientId = args["clientId"] as? String ?: ""
        val envString = args["environment"] as? String ?: "int"
        val e2e = args["e2e"] as? Boolean ?: false
        val logs = args["logs"] as? Boolean ?: false

        val environment = FlexEnvironment.entries.find { it.value == envString } ?: FlexEnvironment.INT
        val config = FlexConfig(clientId = clientId, environment = environment, e2e = e2e, logs = logs)

        val sdk = Flex.initialize(appContext, config)

        // Register a token loader that calls back into Dart when a token is needed.
        sdk.loadToken {
            requestTokenFromDart()
        }

        sdkInitialized = true
        // If the Activity is already attached by now, warm immediately.
        // Otherwise onAttachedToActivity will trigger warmup later.
        maybeWarmup()

        result.success(null)
    }

    private suspend fun requestTokenFromDart(): String {
        return suspendCancellableCoroutine { continuation ->
            scope.launch(Dispatchers.Main) {
                channel.invokeMethod("tokenLoader", null, object : Result {
                    override fun success(response: Any?) {
                        val token = response as? String
                        if (!token.isNullOrEmpty()) {
                            continuation.resume(token)
                        } else {
                            continuation.resumeWithException(
                                IllegalStateException("Dart tokenLoader returned empty token")
                            )
                        }
                    }

                    override fun error(code: String, message: String?, details: Any?) {
                        continuation.resumeWithException(
                            IllegalStateException("Dart tokenLoader error: $message")
                        )
                    }

                    override fun notImplemented() {
                        continuation.resumeWithException(
                            IllegalStateException("Dart tokenLoader not implemented")
                        )
                    }
                })
            }
        }
    }

    // MARK: - Configure Checkout

    private fun handleConfigureCheckout(args: Map<*, *>, result: Result) {
        val interstitial = args["interstitial"] as? Boolean ?: true

        Flex.instance.checkout(
            CheckoutConfig(
                interstitial = interstitial,
                onOpen = {
                    eventSink?.success(mapOf("type" to "open"))
                },
                onClose = {
                    eventSink?.success(mapOf("type" to "close"))
                },
                onError = { error ->
                    eventSink?.success(mapOf("type" to "error", "error" to error))
                },
                onEvent = { event ->
                    eventSink?.success(
                        mapOf(
                            "type" to "event",
                            "eventType" to event.type.value,
                            "data" to mapOf("autopayEnabled" to event.data.autopayEnabled),
                        )
                    )
                }
            )
        )

        result.success(null)
    }

    // MARK: - EventChannel.StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
