package com.flex.checkout.flutter

import android.app.Activity
import android.content.Context
import android.view.View
import com.flex.checkout.components.FlexSplitRentButtonView
import com.flex.checkout.configuration.SplitRentButtonConfig
import com.flex.checkout.types.ButtonStyles
import com.flex.checkout.types.SplitRentButtonColor
import com.flex.checkout.types.SplitRentButtonRadius
import com.flex.checkout.types.SplitRentButtonVariant
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class FlexSplitRentButtonFactory(
    private val activityProvider: () -> Activity?,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any> ?: emptyMap()
        // The native SDK walks the ContextWrapper chain looking for a
        // FragmentActivity. Flutter's PlatformView context doesn't unwrap to
        // one, so fall back to the host Activity which does.
        val viewContext = activityProvider() ?: context
        return FlexSplitRentButtonNativeView(viewContext, params)
    }
}

private class FlexSplitRentButtonNativeView(
    context: Context,
    params: Map<String, Any>,
) : PlatformView {

    private val buttonView = FlexSplitRentButtonView(context)

    init {
        val height = (params["height"] as? Number)?.toFloat()
        val styles = height?.let { ButtonStyles(height = it) }
        val variant = (params["variant"] as? String)?.let(::parseVariant)
        val radius = (params["radius"] as? String)?.let(::parseRadius)
        val color = (params["color"] as? String)?.let(::parseColor)
        buttonView.bind(
            SplitRentButtonConfig(
                styles = styles,
                variant = variant,
                radius = radius,
                color = color,
            )
        )
    }

    override fun getView(): View = buttonView

    override fun dispose() {}

    private fun parseVariant(value: String): SplitRentButtonVariant? =
        when (value) {
            "default" -> SplitRentButtonVariant.DEFAULT
            "list_item" -> SplitRentButtonVariant.LIST_ITEM
            else -> null
        }

    private fun parseRadius(value: String): SplitRentButtonRadius? =
        when (value) {
            "square" -> SplitRentButtonRadius.SQUARE
            "rounded" -> SplitRentButtonRadius.ROUNDED
            "pill" -> SplitRentButtonRadius.PILL
            else -> null
        }

    private fun parseColor(value: String): SplitRentButtonColor? =
        when (value) {
            "purple" -> SplitRentButtonColor.PURPLE
            "white" -> SplitRentButtonColor.WHITE
            else -> null
        }
}
