package com.leaf.malssi

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Settings

// 재부팅 후 잠금 오버레이 복구 (#253).
// 설정이 on + 오버레이 권한이 있으면 서비스를 다시 시작한다.
// Android 12+ 백그라운드 시작 제한에 걸리면 예외를 삼키고,
// 다음 앱 실행 시 동기화(`LockscreenService.setEnabled`)로 복구한다.
class MalssiLockscreenBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        if (!MalssiLockscreenService.isEnabled(context)) return
        if (!Settings.canDrawOverlays(context)) return
        try {
            MalssiLockscreenService.setEnabled(context, true)
        } catch (_: Exception) {
            // 시작 제한·기타 실패는 무시 (다음 앱 실행 시 복구).
        }
    }
}
