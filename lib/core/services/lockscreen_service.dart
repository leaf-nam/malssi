import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 잠금화면 오버레이 네이티브 브릿지 (#253, Android만).
/// `MainActivity`의 `MethodChannel('malssi/lockscreen')`과 통신한다.
/// - `setEnabled`: 포그라운드 서비스 시작/중단 (매 잠금해제 명언 노출 on/off).
/// - `isGranted`: 다른 앱 위에 표시(오버레이) 권한 여부.
/// - `openSettings`: 오버레이 권한 설정 화면 열기.
/// 모든 호출은 실패해도 앱에 영향없게 `false`로 수렴한다 (테스트 포함).
class LockscreenService {
  LockscreenService._internal({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('malssi/lockscreen');

  static final LockscreenService _instance = LockscreenService._internal();
  static LockscreenService get instance => _instance;

  @visibleForTesting
  static LockscreenService testWithChannel(MethodChannel channel) =>
      LockscreenService._internal(channel: channel);

  final MethodChannel _channel;

  /// 오버레이 서비스 상태를 설정과 일치시킨다.
  /// 권한이 없으면 네이티브가 조용히 무시하고 `false`를 돌려준다.
  Future<bool> setEnabled(bool enabled) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setEnabled',
        {'enabled': enabled},
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Lockscreen setEnabled failed: $e');
      return false;
    }
  }

  /// 다른 앱 위에 표시 권한이 있으면 `true`.
  Future<bool> isGranted() async {
    try {
      final result = await _channel.invokeMethod<bool>('isGranted');
      return result ?? false;
    } catch (e) {
      debugPrint('Lockscreen isGranted failed: $e');
      return false;
    }
  }

  /// 오버레이 권한 설정 화면을 연다. 호출 성공 여부를 돌려준다.
  Future<bool> openSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openSettings');
      return result ?? false;
    } catch (e) {
      debugPrint('Lockscreen openSettings failed: $e');
      return false;
    }
  }
}
