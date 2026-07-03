package com.example.vachanamrut_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray

class VachanamrutWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action != ACTION_TOGGLE_WIDGET) {
            return
        }

        val appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            return
        }

        val preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val key = meaningKey(appWidgetId)
        preferences.edit().putBoolean(key, !preferences.getBoolean(key, false)).apply()

        updateWidget(context, AppWidgetManager.getInstance(context), appWidgetId)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val editor = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
        appWidgetIds.forEach { appWidgetId -> editor.remove(meaningKey(appWidgetId)) }
        editor.apply()
    }

    companion object {
        private const val ACTION_TOGGLE_WIDGET =
            "com.example.vachanamrut_app.ACTION_TOGGLE_WIDGET"
        private const val PREFS_NAME = "vachanamrut_widget_preferences"
        private const val ROTATION_INTERVAL_MILLIS = 60L * 60L * 1000L

        fun refreshAll(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val provider = ComponentName(context, VachanamrutWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(provider)
            appWidgetIds.forEach { appWidgetId ->
                updateWidget(context, appWidgetManager, appWidgetId)
            }
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val quote = QuoteRepository.load(context).quoteForNow()
            val showMeaning = context
                .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .getBoolean(meaningKey(appWidgetId), false)

            val views = RemoteViews(context.packageName, R.layout.vachanamrut_widget)
            views.setTextViewText(
                R.id.widget_kicker,
                if (showMeaning) "English Meaning" else quote.reference,
            )
            views.setTextViewText(
                R.id.widget_body,
                if (showMeaning) quote.meaning else quote.quote,
            )
            views.setTextViewText(
                R.id.widget_reference,
                if (showMeaning) "Tap to return to Gujarati" else "Tap to see meaning",
            )
            views.setOnClickPendingIntent(
                R.id.widget_root,
                toggleIntent(context, appWidgetId),
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun toggleIntent(context: Context, appWidgetId: Int): PendingIntent {
            val intent = Intent(context, VachanamrutWidgetProvider::class.java).apply {
                action = ACTION_TOGGLE_WIDGET
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            return PendingIntent.getBroadcast(
                context,
                appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun List<VachanamrutQuote>.quoteForNow(): VachanamrutQuote {
            val index = ((System.currentTimeMillis() / ROTATION_INTERVAL_MILLIS) % size).toInt()
            return this[index]
        }

        private fun meaningKey(appWidgetId: Int) = "show_meaning_$appWidgetId"
    }
}

private data class VachanamrutQuote(
    val reference: String,
    val quote: String,
    val meaning: String,
)

private object QuoteRepository {
    private var cachedQuotes: List<VachanamrutQuote>? = null

    fun load(context: Context): List<VachanamrutQuote> {
        cachedQuotes?.let { return it }

        return try {
            context.assets.open("flutter_assets/assets/vachanamrut_quotes.json").use { stream ->
                val json = stream.bufferedReader().readText()
                parseQuotes(json).also { cachedQuotes = it }
            }
        } catch (_: Exception) {
            fallbackQuotes().also { cachedQuotes = it }
        }
    }

    private fun parseQuotes(json: String): List<VachanamrutQuote> {
        val array = JSONArray(json)
        return List(array.length()) { index ->
            val item = array.getJSONObject(index)
            VachanamrutQuote(
                reference = item.getString("reference"),
                quote = item.getString("quote"),
                meaning = item.getString("meaning"),
            )
        }
    }

    private fun fallbackQuotes() = listOf(
        VachanamrutQuote(
            reference = "Quote 1",
            quote = "આ દેહ ભગવાનની ભક્તિ માટે મળ્યો છે.",
            meaning = "This body has been received for devotion to God.",
        ),
    )
}
