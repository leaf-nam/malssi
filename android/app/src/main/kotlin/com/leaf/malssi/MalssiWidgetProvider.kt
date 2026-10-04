package com.leaf.malssi

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.Duration
import java.time.OffsetDateTime

// 홈 위젯: 오늘의 명언 + 저자 + 성장 상태 (#139, #242).
// 데이터는 Flutter(HomeWidgetService)가 저장하고, 탭하면 말씨 탭으로 이동한다.
// 남은시간은 저장된 시각(ISO8601) 기준으로 계산한다.
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
                bindGrowth(this, widgetData)
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

    private fun bindGrowth(views: RemoteViews, widgetData: SharedPreferences) {
        val status = widgetData.getString("seed_status", "locked") ?: "locked"
        val stage = widgetData.getInt("growth_stage", 0)
        when {
            status == "complete" -> {
                views.setTextViewText(R.id.widget_stage, "🎉 수확 완료")
                views.setViewVisibility(R.id.widget_stage, View.VISIBLE)
                views.setViewVisibility(R.id.widget_countdown, View.GONE)
            }
            status == "growing" -> {
                views.setTextViewText(R.id.widget_stage, "🌱 자라는 중 · ${stage}단계")
                views.setViewVisibility(R.id.widget_stage, View.VISIBLE)
                val parts = listOfNotNull(
                    remainingText(widgetData.getString("next_stage_at", ""), "다음 단계까지"),
                    remainingText(widgetData.getString("complete_at", ""), "완성까지"),
                )
                if (parts.isEmpty()) {
                    views.setViewVisibility(R.id.widget_countdown, View.GONE)
                } else {
                    views.setTextViewText(R.id.widget_countdown, parts.joinToString(" · "))
                    views.setViewVisibility(R.id.widget_countdown, View.VISIBLE)
                }
            }
            else -> {
                views.setViewVisibility(R.id.widget_stage, View.GONE)
                views.setViewVisibility(R.id.widget_countdown, View.GONE)
            }
        }
    }

    private fun remainingText(iso: String?, prefix: String): String? {
        if (iso.isNullOrEmpty()) return null
        val target = try {
            OffsetDateTime.parse(iso)
        } catch (e: Exception) {
            return null
        }
        val seconds = Duration.between(OffsetDateTime.now(), target).seconds
        if (seconds <= 0) return null
        return "${prefix}까지 ${formatDuration(seconds)}"
    }

    private fun formatDuration(totalSeconds: Long): String {
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        return when {
            hours > 0 && minutes > 0 -> "약 ${hours}시간 ${minutes}분"
            hours > 0 -> "약 ${hours}시간"
            minutes > 0 -> "약 ${minutes}분"
            else -> "곧"
        }
    }
}
