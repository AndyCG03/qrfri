package com.qrfri.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/** Compact launcher widget with direct access to QRfri's two core workflows. */
class QrFriWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { id -> manager.updateAppWidget(id, views(context)) }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        val manager = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, QrFriWidgetProvider::class.java)
        onUpdate(context, manager, manager.getAppWidgetIds(component))
    }

    private fun views(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.qrfri_widget)
        val black = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(THEME_KEY, "light") == "black"
        views.setInt(R.id.qrfri_widget_root, "setBackgroundResource", if (black) R.drawable.qrfri_widget_dark_background else R.drawable.qrfri_widget_background)
        views.setInt(R.id.qrfri_widget_scan, "setBackgroundResource", if (black) R.drawable.qrfri_widget_dark_scan_button else R.drawable.qrfri_widget_scan_button)
        views.setInt(R.id.qrfri_widget_search, "setBackgroundResource", if (black) R.drawable.qrfri_widget_dark_search_button else R.drawable.qrfri_widget_search_button)
        views.setInt(
            R.id.qrfri_widget_search,
            "setColorFilter",
            if (black) 0xffffffff.toInt() else 0xff3730e0.toInt(),
        )
        views.setOnClickPendingIntent(R.id.qrfri_widget_scan, pendingIntent(context, MainActivity.ACTION_SCAN, 10))
        views.setOnClickPendingIntent(R.id.qrfri_widget_search, pendingIntent(context, MainActivity.ACTION_SEARCH, 11))
        return views
    }

    private fun pendingIntent(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            this.action = action
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        const val PREFS = "qrfri_widget_preferences"
        const val THEME_KEY = "theme"

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, QrFriWidgetProvider::class.java)
            val provider = QrFriWidgetProvider()
            provider.onUpdate(context, manager, manager.getAppWidgetIds(component))
        }
    }
}
