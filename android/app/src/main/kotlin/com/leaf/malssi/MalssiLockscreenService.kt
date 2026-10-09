package com.leaf.malssi

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import androidx.core.content.ContextCompat
import java.time.LocalDate

// 켤 때마다 먼저 보는 잠금 오버레이 (#253).
// 포그라운드 서비스가 화면 켜짐(잠금 상태)을 감지해 오늘 명언을 띄우고,
// 잠금 해제·화면 꺼짐에 숨긴다. 명언 원천은 홈 위젯과 같은
// `HomeWidgetPreferences`다 (위젯 동기화 재사용, 날짜 가드 포함).
class MalssiLockscreenService : Service() {

    private var overlayView: View? = null

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            android.util.Log.d(TAG, "screen event: ${intent.action}")
            when (intent.action) {
                Intent.ACTION_SCREEN_ON -> showOverlay()
                Intent.ACTION_USER_PRESENT,
                Intent.ACTION_SCREEN_OFF -> hideOverlay()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        android.util.Log.d(TAG, "service created")
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        // Android 14+는 export 플래그 필수 (2-arg 호출은 SecurityException).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(screenReceiver, filter)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        android.util.Log.d(TAG, "service started")
        startForeground(NOTIF_ID, buildServiceNotification())
        return START_STICKY
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(screenReceiver)
        } catch (_: IllegalArgumentException) {
            // 미등록 상태 해제 시도는 무시한다.
        }
        hideOverlay()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // 화면이 켜질 때마다 명언 오버레이를 보여준다 (#253).
    // 잠금 여부와 무관하게 띄운다: 잠금 설정 없음(None)에서도
    // "켤 때마다 명언" 요구를 만족하고, 잠금 해제·탭·화면 꺼짐에 사라진다.
    private fun showOverlay() {
        if (overlayView != null) {
            android.util.Log.d(TAG, "overlay already shown")
            return
        }
        if (!Settings.canDrawOverlays(this)) {
            android.util.Log.d(TAG, "overlay skipped: permission revoked")
            return
        }

        val view = LayoutInflater.from(this)
            .inflate(R.layout.lockscreen_overlay, null)
        fillQuote(view)
        view.findViewById<View>(R.id.lock_root).setOnClickListener {
            hideOverlay()
            startActivity(
                Intent(this, MainActivity::class.java).apply {
                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
                    )
                },
            )
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            overlayType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply { gravity = Gravity.TOP }
        getSystemService(WindowManager::class.java).addView(view, params)
        overlayView = view
        android.util.Log.d(TAG, "overlay shown")
    }

    private fun hideOverlay() {
        val view = overlayView ?: return
        overlayView = null
        try {
            getSystemService(WindowManager::class.java).removeView(view)
            android.util.Log.d(TAG, "overlay hidden")
        } catch (_: IllegalArgumentException) {
            // 이미 제거된 뷰는 무시한다.
        }
    }

    private fun overlayType(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
    }

    private fun fillQuote(view: View) {
        // 위젯과 같은 저장소·키를 읽는다 (#139, #242).
        val prefs = getSharedPreferences(
            "HomeWidgetPreferences",
            Context.MODE_PRIVATE,
        )
        val today = LocalDate.now().toString()
        val sameDay = prefs.getString("seed_date", "") == today
        val text = prefs.getString("quote_text", "").orEmpty()
        val quote = view.findViewById<android.widget.TextView>(R.id.lock_quote)
        val author =
            view.findViewById<android.widget.TextView>(R.id.lock_author)
        val image =
            view.findViewById<android.widget.ImageView>(R.id.lock_image)
        val status = prefs.getString("seed_status", "").orEmpty()
        val stage = prefs.getInt("growth_stage", 0)
        val theme = prefs.getString("seed_theme", "").orEmpty()
        val countdown =
            view.findViewById<android.widget.TextView>(R.id.lock_countdown)
        // 날짜가 바뀌었거나(앱 미실행) 명언이 없으면 자리 문구를 보여준다.
        if (sameDay && text.isNotEmpty()) {
            quote.text = "“$text”"
            val by = prefs.getString("quote_author", "").orEmpty()
            author.text = if (by.isEmpty()) "말씨" else "— $by"
            fillGrowthImage(image, theme, status, stage)
            // 말씨 탭과 같은 남은시간 표기 (#138, 작은 글씨).
            // 성장 중이 아니면 숨긴다.
            val remaining = remainingText(
                prefs.getString("next_stage_at", "").orEmpty(),
                status,
            )
            if (remaining.isEmpty()) {
                countdown.visibility = View.GONE
            } else {
                countdown.text = remaining
                countdown.visibility = View.VISIBLE
            }
        } else {
            quote.text = "오늘의 씨앗을 심어보세요"
            author.text = "말씨"
            fillGrowthImage(image, theme, "locked", 0)
            countdown.visibility = View.GONE
        }
    }

    // 다음 성장까지 남은시간 (`다음 성장까지 01:23`, `HH:MM` 2자리 고정).
    // 1분 미만은 올림하고, 지났거나 성장 중이 아니면 `''`
    // (`formatGrowthTimer` Dart와 동일 규칙, #138).
    private fun remainingText(nextStageAtIso: String, status: String): String {
        if (status != "growing" || nextStageAtIso.isEmpty()) return ""
        return try {
            val seconds = java.time.Duration.between(
                java.time.Instant.now(),
                java.time.Instant.parse(nextStageAtIso),
            ).seconds
            if (seconds <= 0) return ""
            val minutes = ((seconds + 59) / 60).toInt()
            val text = "%02d:%02d".format(minutes / 60, minutes % 60)
            "다음 성장까지 $text"
        } catch (_: Exception) {
            ""
        }
    }

    // 성장 에셋을 Flutter 번들에서 직접 읽는다 (#253).
    // `res` 복제 없이 `flutter_assets`를 디코딩한다.
    // - 완성: `<이름>.png`, 0단계·잠금: `<이름>_seed.png`,
    // - 1~5단계: `<이름>-<n>.png` (`ThemeAssets.growthImage`와 동일 규칙).
    // 미등록 테마·실패 시 이미지를 숨긴다.
    private fun fillGrowthImage(
        image: android.widget.ImageView,
        theme: String,
        status: String,
        stage: Int,
    ) {
        val name = fruitName(theme)
        if (name.isEmpty()) {
            image.visibility = View.GONE
            return
        }
        val file = when {
            status == "complete" -> "$name.png"
            stage <= 0 -> "${name}_seed.png"
            else -> "$name-$stage.png"
        }
        try {
            assets.open("flutter_assets/assets/images/$file").use { stream ->
                val bitmap =
                    android.graphics.BitmapFactory.decodeStream(stream)
                if (bitmap == null) {
                    image.visibility = View.GONE
                } else {
                    image.setImageBitmap(bitmap)
                    image.visibility = View.VISIBLE
                }
            }
        } catch (_: Exception) {
            android.util.Log.d(TAG, "growth image missing: $file")
            image.visibility = View.GONE
        }
    }

    private fun fruitName(theme: String): String {
        return when (theme) {
            "vitality" -> "strawberry"
            "happiness" -> "orange"
            "growth" -> "lemon"
            "health" -> "kiwi"
            "peace" -> "blueberry"
            "relationship" -> "grape"
            "wisdom" -> "grapefruit"
            else -> ""
        }
    }

    private fun buildServiceNotification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "잠금화면 먼저 보기",
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
        val tap = PendingIntent.getActivity(
            this,
            300,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("말씨가 잠금화면을 준비 중이에요")
            .setContentText("켤 때마다 오늘의 명언을 먼저 보여줘요")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(tap)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
    }

    companion object {
        private const val TAG = "MalssiLockscreen"
        private const val CHANNEL_ID = "malssi_lockscreen_service"
        private const val NOTIF_ID = 3001
        private const val PREFS = "MalssiLockscreen"
        private const val KEY_ENABLED = "enabled"

        fun isEnabled(context: Context): Boolean {
            return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_ENABLED, false)
        }

        /// 오버레이 on/off. 권한이 없으면 저장만 하고 `false`를 돌려준다.
        /// 상태가 같으면 아무 것도 하지 않는다.
        fun setEnabled(context: Context, enabled: Boolean): Boolean {
            val app = context.applicationContext
            app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_ENABLED, enabled)
                .apply()
            android.util.Log.d(TAG, "setEnabled($enabled)")
            val running = isRunning(app)
            if (enabled && !Settings.canDrawOverlays(app)) return false
            if (enabled && !running) {
                ContextCompat.startForegroundService(
                    app,
                    Intent(app, MalssiLockscreenService::class.java),
                )
            } else if (!enabled && running) {
                app.stopService(
                    Intent(app, MalssiLockscreenService::class.java),
                )
            }
            return enabled
        }

        private fun isRunning(context: Context): Boolean {
            val manager =
                context.getSystemService(Context.ACTIVITY_SERVICE)
                    as android.app.ActivityManager
            @Suppress("DEPRECATION")
            return manager.getRunningServices(Int.MAX_VALUE)
                .any { it.service.className == MalssiLockscreenService::class.java.name }
        }
    }
}
