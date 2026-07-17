package com.flex.checkout.flutter

import android.app.Activity
import android.content.Context
import android.view.View
import com.flex.checkout.components.FlexStatusCardView
import com.flex.checkout.configuration.StatusCardConfig
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class FlexStatusCardFactory(
    private val activityProvider: () -> Activity?,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        // The native SDK walks the ContextWrapper chain looking for a
        // FragmentActivity. Flutter's PlatformView context doesn't unwrap to
        // one, so fall back to the host Activity which does.
        val viewContext = activityProvider() ?: context
        return FlexStatusCardNativeView(viewContext)
    }
}

private class FlexStatusCardNativeView(
    context: Context,
) : PlatformView {

    private val cardView = FlexStatusCardView(context)

    init {
        cardView.bind(StatusCardConfig())
    }

    override fun getView(): View = cardView

    override fun dispose() {}
}
