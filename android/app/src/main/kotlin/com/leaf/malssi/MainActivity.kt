package com.leaf.malssi

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.istornz.live_activities.LiveActivityManagerHolder

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 성장 Live Activity용 알림 렌더러 등록 (#248).
        LiveActivityManagerHolder.instance =
            MalssiLiveActivityManager(this)
    }
}
