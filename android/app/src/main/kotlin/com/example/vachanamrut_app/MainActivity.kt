package com.example.vachanamrut_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPinWidget" -> result.success(requestPinWidget())
                    "refreshWidgets" -> {
                        VachanamrutWidgetProvider.refreshAll(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestPinWidget(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return false
        }

        val appWidgetManager = AppWidgetManager.getInstance(this)
        if (!appWidgetManager.isRequestPinAppWidgetSupported) {
            return false
        }

        val provider = ComponentName(this, VachanamrutWidgetProvider::class.java)
        val successCallback = PendingIntent.getBroadcast(
            this,
            0,
            Intent(this, VachanamrutWidgetProvider::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        appWidgetManager.requestPinAppWidget(provider, null, successCallback)
        return true
    }

    private companion object {
        const val WIDGET_CHANNEL = "vachanamrut_app/widget"
    }
}
