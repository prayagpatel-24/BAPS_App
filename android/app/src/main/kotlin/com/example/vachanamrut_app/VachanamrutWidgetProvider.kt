package com.example.vachanamrut_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

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
            val preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val widgetState = WidgetState.fromPreferences(preferences)
            val showMeaning = preferences.getBoolean(meaningKey(appWidgetId), false)
            val content = when (widgetState.widgetContentMode) {
                "mukhpath" -> widgetState.mukhpathContentForNow()
                else -> widgetState.quoteContentForNow(showMeaning)
            }

            val views = RemoteViews(context.packageName, R.layout.vachanamrut_widget)
            views.setTextViewText(R.id.widget_kicker, content.kicker)
            views.setTextViewText(R.id.widget_body, content.body)
            views.setTextViewText(R.id.widget_reference, content.reference)
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

        private fun meaningKey(appWidgetId: Int) = "show_meaning_$appWidgetId"
    }
}

private data class WidgetContent(
    val kicker: String,
    val body: String,
    val reference: String,
)

private data class WidgetState(
    val appMode: String,
    val widgetContentMode: String,
    val language: String,
    val quoteIntervalMinutes: Int,
    val mukhpathIntervalMinutes: Int,
    val completedMukhpathIds: Set<String>,
    val quotes: List<VachanamrutQuote>,
    val mukhpathItems: List<MukhpathItem>,
) {
    fun quoteContentForNow(showMeaning: Boolean): WidgetContent {
        val quote = quotes.quoteForNow(quoteIntervalMinutes)
        return when (language) {
            "english" -> WidgetContent(
                kicker = "English Meaning",
                body = quote.meaning,
                reference = "English preview",
            )
            "gujaratiWithEnglish" -> WidgetContent(
                kicker = if (showMeaning) "English Meaning" else quote.reference,
                body = if (showMeaning) quote.meaning else quote.quote,
                reference = if (showMeaning) "Tap to return to Gujarati" else "Tap to see meaning",
            )
            else -> WidgetContent(
                kicker = if (showMeaning) "English Meaning" else quote.reference,
                body = if (showMeaning) quote.meaning else quote.quote,
                reference = if (showMeaning) "Tap to return to Gujarati" else "Tap to see meaning",
            )
        }
    }

    fun mukhpathContentForNow(): WidgetContent {
        val visibleItems = mukhpathItems.filterNot { completedMukhpathIds.contains(it.id) }
        val item = visibleItems.mukhpathForNow(mukhpathIntervalMinutes)
        return when (language) {
            "english" -> WidgetContent(
                kicker = "Mukhpath",
                body = item.englishQuestion,
                reference = item.englishAnswer,
            )
            "gujaratiWithEnglish" -> WidgetContent(
                kicker = "Mukhpath",
                body = "${item.question}\n\n${item.englishQuestion}",
                reference = "${item.answer}\n\n${item.englishAnswer}",
            )
            else -> WidgetContent(
                kicker = "Mukhpath",
                body = item.question,
                reference = item.answer,
            )
        }
    }

    companion object {
        fun fromPreferences(preferences: android.content.SharedPreferences): WidgetState {
            val appMode = preferences.getString("appMode", "vachanamrut") ?: "vachanamrut"
            val widgetContentMode = preferences.getString("widgetContentMode", "vachanamrut") ?: "vachanamrut"
            val language = preferences.getString("language", "gujarati") ?: "gujarati"
            val quoteIntervalMinutes = preferences.getInt("quoteIntervalMinutes", 60)
            val mukhpathIntervalMinutes = preferences.getInt("mukhpathIntervalMinutes", 60)
            val completedIds = preferences.getStringSet("completedMukhpathIds", emptySet()) ?: emptySet()
            val quotes = parseQuotes(preferences.getString("quotesJson", null) ?: "[]")
            val mukhpathItems = parseMukhpath(preferences.getString("mukhpathJson", null) ?: "[]")
            return WidgetState(
                appMode = appMode,
                widgetContentMode = widgetContentMode,
                language = language,
                quoteIntervalMinutes = quoteIntervalMinutes,
                mukhpathIntervalMinutes = mukhpathIntervalMinutes,
                completedMukhpathIds = completedIds,
                quotes = quotes,
                mukhpathItems = mukhpathItems,
            )
        }
    }
}

private data class VachanamrutQuote(
    val reference: String,
    val title: String,
    val quote: String,
    val meaning: String,
)

private data class MukhpathItem(
    val id: String,
    val question: String,
    val answer: String,
    val englishQuestion: String,
    val englishAnswer: String,
)

private fun List<VachanamrutQuote>.quoteForNow(intervalMinutes: Int): VachanamrutQuote {
    if (isEmpty()) return VachanamrutQuote("Quote 1", "", "", "")
    val intervalMillis = intervalMinutes.coerceAtLeast(1) * 60L * 1000L
    val index = ((System.currentTimeMillis() / intervalMillis) % size).toInt()
    return this[index]
}

private fun List<MukhpathItem>.mukhpathForNow(intervalMinutes: Int): MukhpathItem {
    if (isEmpty()) return MukhpathItem("", "No Mukhpath items available.", "", "No Mukhpath items available.", "")
    val intervalMillis = intervalMinutes.coerceAtLeast(1) * 60L * 1000L
    val index = ((System.currentTimeMillis() / intervalMillis) % size).toInt()
    return this[index]
}

private fun parseQuotes(json: String): List<VachanamrutQuote> {
    val array = JSONArray(json)
    return List(array.length()) { index ->
        val item = array.getJSONObject(index)
        VachanamrutQuote(
            reference = item.optString("reference", ""),
            title = item.optString("title", ""),
            quote = item.optString("quote", ""),
            meaning = item.optString("meaning", ""),
        )
    }
}

private fun parseMukhpath(json: String): List<MukhpathItem> {
    val array = JSONArray(json)
    return List(array.length()) { index ->
        val item = array.getJSONObject(index)
        MukhpathItem(
            id = item.optString("id", ""),
            question = item.optString("question", ""),
            answer = item.optString("answer", ""),
            englishQuestion = item.optString("englishQuestion", item.optString("question", "")),
            englishAnswer = item.optString("englishAnswer", item.optString("answer", "")),
        )
    }
}
