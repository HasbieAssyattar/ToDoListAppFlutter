package com.hasbi.todolist_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TodoWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.todo_widget_layout)

            val activeCount = widgetData.getInt("active_count", 0)
            val topTitle = widgetData.getString("top_task_title", "Tidak ada tugas aktif") ?: "Tidak ada tugas aktif"
            val topStatus = widgetData.getString("top_task_status", "Ketuk untuk membuka aplikasi") ?: "Ketuk untuk membuka aplikasi"

            views.setTextViewText(R.id.widget_active_badge, "$activeCount Aktif")
            views.setTextViewText(R.id.widget_task_title, topTitle)
            views.setTextViewText(R.id.widget_task_status, topStatus)

            // Click pending intent to launch MainActivity
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
