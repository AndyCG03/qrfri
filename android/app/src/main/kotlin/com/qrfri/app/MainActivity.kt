package com.qrfri.app

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        widgetChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialAction" -> {
                    result.success(actionForIntent(intent))
                    // Avoid replaying the same action after a Flutter rebuild.
                    intent.action = Intent.ACTION_MAIN
                }
                "setTheme" -> {
                    val value = call.arguments?.toString() ?: "light"
                    getSharedPreferences(QrFriWidgetProvider.PREFS, MODE_PRIVATE)
                        .edit().putString(QrFriWidgetProvider.THEME_KEY, if (value == "black") "black" else "light").apply()
                    QrFriWidgetProvider.updateAll(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(newIntent: Intent) {
        super.onNewIntent(newIntent)
        setIntent(newIntent)
        actionForIntent(newIntent)?.let { action ->
            widgetChannel?.invokeMethod("open", action)
        }
    }

    private fun actionForIntent(source: Intent?): String? = when (source?.action) {
        ACTION_SCAN -> "scan"
        ACTION_SEARCH -> "search"
        else -> null
    }

    companion object {
        const val CHANNEL = "com.qrfri.app/widget"
        const val ACTION_SCAN = "com.qrfri.app.action.SCAN"
        const val ACTION_SEARCH = "com.qrfri.app.action.SEARCH"
    }
}
