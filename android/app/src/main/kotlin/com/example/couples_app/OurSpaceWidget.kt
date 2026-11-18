package com.example.couples_app // Если у тебя другой package в MainActivity.kt, укажи его здесь

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class OurSpaceWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Извлекаем переданные из Flutter данные
                val noteText = widgetData.getString("note_text", "Пока нет записок")
                val emoji = widgetData.getString("note_emoji", "💌")
                val counterText = widgetData.getString("counter_text", "Our Space")

                setTextViewText(R.id.widget_note_text, noteText)
                setTextViewText(R.id.widget_emoji, emoji)
                setTextViewText(R.id.widget_counter_text, counterText)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}