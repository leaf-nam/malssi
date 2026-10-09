import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';

/// Live Activity 호출 추상화 (#248).
/// 실제 구현은 `live_activities` 플러그인, 테스트에서는 fake을 주입한다
/// (플랫폼 채널은 테스트에서 응답하지 않아 실호출 시 멈춘다).
abstract class LiveActivityGateway {
  Future<void> init({required String appGroupId});
  Future<bool> areEnabled();
  Future<void> createOrUpdate(
    String activityId,
    Map<String, dynamic> data, {
    Duration? staleIn,
  });
  Future<void> end(String activityId);
}

/// `live_activities` 플러그인 기반 호출 (실기기용).
class LiveActivitiesPluginGateway implements LiveActivityGateway {
  final LiveActivities _plugin = LiveActivities();

  @override
  Future<void> init({required String appGroupId}) => _plugin.init(
        appGroupId: appGroupId,
        // OS 알림 권한은 앱 자체 흐름(#244 후속)에서 요청하므로 중복 요청 안 함.
        requestAndroidNotificationPermission: false,
      );

  @override
  Future<bool> areEnabled() => _plugin.areActivitiesEnabled();

  @override
  Future<void> createOrUpdate(
    String activityId,
    Map<String, dynamic> data, {
    Duration? staleIn,
  }) =>
      _plugin.createOrUpdateActivity(
        activityId,
        data,
        // 원격 푸시 갱신 미사용 (Push capability 불필요).
        iOSEnableRemoteUpdates: false,
        staleIn: staleIn,
      );

  @override
  Future<void> end(String activityId) => _plugin.endActivity(activityId);
}

/// 성장 Live Activity 동기화 (#248).
/// 1단계 도달 시 시작해 단계마다 갱신하고, 수확·미심김 시 종료한다.
/// iOS 8시간 제한에 걸리지 않게 1단계(2시간 경과)부터 시작한다 (2+8=10시간 커버).
/// 같은 명언·단계면 다시 요청하지 않는다. 실패해도 앱에 영향없다.
class LiveActivityService {
  LiveActivityService({LiveActivityGateway? gateway})
      : _gateway = gateway ?? LiveActivitiesPluginGateway();

  static LiveActivityService _instance = LiveActivityService();
  static LiveActivityService get instance => _instance;

  @visibleForTesting
  static set instance(LiveActivityService service) => _instance = service;

  /// iOS App Group (`HomeWidgetService`와 공유).
  static const appGroupId = 'group.com.leaf.malssi';

  static String activityIdFor(String dateKey) => 'growth-$dateKey';

  final LiveActivityGateway _gateway;

  /// 마지막으로 반영한 스냅샷 키 (중복 갱신 방지용).
  String? _lastKey;

  /// 이번 세션에 시작한 Activity (종료 중복 호출 방지용).
  final Set<String> _activeIds = {};

  /// 플러그인 초기화. `main()`에서 1회 호출한다.
  Future<void> init() async {
    try {
      await _gateway.init(appGroupId: appGroupId);
    } catch (e) {
      debugPrint('LiveActivity init failed: $e');
    }
  }

  /// 씨앗 스냅샷을 Live Activity에 반영한다.
  /// [completeAtIso]는 UTC ISO8601 (위젯과 동일 형식).
  Future<void> syncSeed({
    required String dateKey,
    required String quoteText,
    required String status,
    required int stage,
    String completeAtIso = '',
  }) async {
    final id = activityIdFor(dateKey);
    try {
      if (status == 'growing' && stage >= 1) {
        final key = '$id|$stage';
        // 날짜가 바뀌면 전날 Activity를 정리한다.
        for (final active in _activeIds.toList()) {
          if (active != id) {
            await _gateway.end(active);
            _activeIds.remove(active);
          }
        }
        if (key == _lastKey) return;
        if (!await _gateway.areEnabled()) return;
        final completeAt = DateTime.tryParse(completeAtIso);
        await _gateway.createOrUpdate(id, {
          'quote_text': quoteText,
          'stage': stage,
          'complete_at': completeAt?.millisecondsSinceEpoch ?? 0,
        }, staleIn: _staleIn(completeAt));
        _activeIds.add(id);
        _lastKey = key;
      } else {
        if (!_activeIds.contains(id)) return;
        await _gateway.end(id);
        _activeIds.remove(id);
      }
    } catch (e) {
      debugPrint('LiveActivity sync failed: $e');
    }
  }

  /// iOS stale 처리: 완성 시각까지 남은 분 (최소 1분, 과거면 null).
  Duration? _staleIn(DateTime? completeAt) {
    if (completeAt == null) return null;
    final minutes = completeAt.difference(DateTime.now()).inMinutes;
    if (minutes < 1) return null;
    return Duration(minutes: minutes);
  }
}
