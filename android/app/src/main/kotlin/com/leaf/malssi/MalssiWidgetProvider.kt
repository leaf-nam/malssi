package com.leaf.malssi

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

// 홈 위젯: 오늘의 명언 + 저자 (#139).
// 데이터는 Flutter(HomeWidgetService)가 저장하고, 탭하면 말씨 탭으로 이동한다.
class MalssiWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.malssi_widget).apply {
                setTextViewText(
                    R.id.widget_quote,
                    widgetData.getString("quote_text", null)
                        ?: "씨앗을 심으면 오늘의 명언이 보여요",
                )
                setTextViewText(
                    R.id.widget_author,
                    widgetData.getString("quote_author", null) ?: "malssi",
                )
                val pending = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("malssi://widget?target=seed"),
                )
                setOnClickPendingIntent(R.id.widget_root, pending)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
