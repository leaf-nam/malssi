package com.leaf.malssi

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.istornz.live_activities.LiveActivityManagerHolder

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 성장 Live Activity용 알림 렌더러 등록 (#248).
        LiveActivityManagerHolder.instance =
            MalssiLiveActivityManager(this)

        // 켤 때마다 먼저 보는 잠금 오버레이 브릿지 (#253).
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "malssi/lockscreen",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setEnabled" -> {
                    val enabled =
                        call.argument<Boolean>("enabled") ?: false
                    result.success(
                        MalssiLockscreenService.setEnabled(this, enabled),
                    )
                }
                "isGranted" ->
                    result.success(Settings.canDrawOverlays(this))
                "openSettings" -> {
                    startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName"),
                        ),
                    )
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
