package com.leaf.malssi

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.istornz.live_activities.LiveActivityManager
import java.time.Duration
import java.time.Instant

// 성장 Live Activity의 Android 알림 렌더러 (#248).
// Dart(`LiveActivityService`)가 보낸 단계·완성시각으로
// 잠금화면 진행 중 알림을 그린다.
class MalssiLiveActivityManager(context: Context) :
    LiveActivityManager(context) {
    private val appContext: Context = context.applicationContext
    private val pendingIntent = PendingIntent.getActivity(
        context,
        200,
        Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private val remoteViews = RemoteViews(
        context.packageName,
        R.layout.live_activity,
    )

    override suspend fun buildNotification(
        notification: Notification.Builder,
        event: String,
        data: Map<String, Any>,
    ): Notification {
        val quote = data["quote_text"] as? String ?: ""
        val stage = (data["stage"] as? Number)?.toInt() ?: 0
        val completeAtMillis = (data["complete_at"] as? Number)?.toLong() ?: 0L

        remoteViews.setTextViewText(R.id.live_quote, quote)
        remoteViews.setTextViewText(
            R.id.live_stage,
            "🌱 자라는 중 · ${stage}단계",
        )
        remoteViews.setTextViewText(
            R.id.live_countdown,
            remainingText(completeAtMillis),
        )
        remoteViews.setOnClickPendingIntent(R.id.live_root, pendingIntent)

        return notification
            .setContent(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
    }

    private fun remainingText(completeAtMillis: Long): String {
        if (completeAtMillis <= 0) return ""
        val seconds = Duration.between(
            Instant.now(),
            Instant.ofEpochMilli(completeAtMillis),
        ).seconds
        if (seconds <= 0) return "곧 수확해요"
        val hours = seconds / 3600
        val minutes = (seconds % 3600) / 60
        return when {
            hours > 0 && minutes > 0 -> "완성까지 약 ${hours}시간 ${minutes}분"
            hours > 0 -> "완성까지 약 ${hours}시간"
            minutes > 0 -> "완성까지 약 ${minutes}분"
            else -> "곧 수확해요"
        }
    }
}
