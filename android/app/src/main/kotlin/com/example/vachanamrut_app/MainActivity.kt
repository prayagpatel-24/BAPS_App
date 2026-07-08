package com.example.vachanamrut_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

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
                    "syncState" -> {
                        val payload = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                        persistWidgetState(this, payload)
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

    private fun persistWidgetState(context: Context, payload: Map<*, *>) {
        val preferences = context.getSharedPreferences(WIDGET_PREFS_NAME, Context.MODE_PRIVATE)
        val editor = preferences.edit()
        editor.putString("appMode", payload["appMode"] as? String ?: "vachanamrut")
        editor.putString("widgetContentMode", payload["widgetContentMode"] as? String ?: "vachanamrut")
        editor.putInt("quoteIntervalMinutes", (payload["quoteIntervalMinutes"] as? Number)?.toInt() ?: 60)
        editor.putInt("mukhpathIntervalMinutes", (payload["mukhpathIntervalMinutes"] as? Number)?.toInt() ?: 60)
        editor.putString("language", payload["language"] as? String ?: "gujarati")
        val completedIds = payload["completedMukhpathIds"] as? List<*>
        editor.putStringSet("completedMukhpathIds", completedIds?.filterIsInstance<String>()?.toSet() ?: emptySet<String>())
        val quotes = payload["quotes"] as? List<*>
        if (quotes != null) {
            val array = JSONArray()
            quotes.forEach { item ->
                val map = item as? Map<*, *>
                val json = JSONObject()
                json.put("reference", map?.get("reference") as? String ?: "")
                json.put("title", map?.get("title") as? String ?: "")
                json.put("quote", map?.get("quote") as? String ?: "")
                json.put("meaning", map?.get("meaning") as? String ?: "")
                array.put(json)
            }
            editor.putString("quotesJson", array.toString())
        }
        val mukhpathItems = payload["mukhpathItems"] as? List<*>
        if (mukhpathItems != null) {
            val array = JSONArray()
            mukhpathItems.forEach { item ->
                val map = item as? Map<*, *>
                val json = JSONObject()
                json.put("id", map?.get("id") as? String ?: "")
                json.put("question", map?.get("question") as? String ?: "")
                json.put("answer", map?.get("answer") as? String ?: "")
                array.put(json)
            }
            editor.putString("mukhpathJson", array.toString())
        }
        editor.apply()
    }

    private companion object {
        const val WIDGET_CHANNEL = "vachanamrut_app/widget"
        const val WIDGET_PREFS_NAME = "vachanamrut_widget_preferences"
    }
}
