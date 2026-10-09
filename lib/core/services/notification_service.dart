import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  /// 씨앗 도착 일일 알림 ID.
  static const seedNotificationId = 1001;

  /// 씨앗 완성(열매) 1회 알림 ID (#140).
  static const seedCompleteNotificationId = 1002;

  /// 마감 리마인드 1회 알림 ID (#147). 당일 13:00 고정.
  static const seedReminderNotificationId = 1003;

  /// 성장 단계 도달 1회 알림 ID (#244). 1~4단계 → 2001~2004.
  /// 5단계 도달은 완성 알림(#140)이 담당한다.
  /// 예약·취소는 기존 1회 알림 API를 그대로 쓴다.
  static int growthNotificationId(int stage) => 2000 + stage;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init(
      {void Function()? onTap,
      @visibleForTesting Future<String> Function()? localTimezoneProvider}) async {
    tz_data.initializeTimeZones();
    // #164: 초기화 직후 `tz.local`은 UTC이므로 기기 타임존으로 바꾼다.
    // 바꾸지 않으면 일일 알림 wall-clock이 UTC로 해석돼 9시간 어긋난다.
    await configureLocalTimezone(provider: localTimezoneProvider);
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _plugin.initialize(
      settings: settings,
      // 알림 탭 → 말씨 탭(`/`) 이동은 호출자(`main()`)가 주입한다 (#140).
      onDidReceiveNotificationResponse: (_) => onTap?.call(),
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduleTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    // inexact 모드: SCHEDULE_EXACT_ALARM 권한 불필요 (수분 오차 허용).
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduleTime, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// 매일 [hour]:[minute]에 씨앗 도착 알림을 반복 예약한다.
  /// `matchDateTimeComponents: time`으로 일일 반복된다.
  /// inexact 모드이므로 SCHEDULE_EXACT_ALARM 권한이 필요 없고,
  /// 수분 단위 오차가 발생할 수 있다 (일일 씨앗 알림 용도로 허용).
  /// [lockscreenFirst]가 true면 full-screen intent를 붙여 (#253, Android만)
  /// 잠금 상태에서도 씨앗 도착 화면을 먼저 보여준다.
  /// Android 14+에서는 `USE_FULL_SCREEN_INTENT` 권한 허용이 필요하다.
  Future<void> scheduleDailySeedNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    bool lockscreenFirst = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      category: lockscreenFirst ? AndroidNotificationCategory.alarm : null,
      fullScreenIntent: lockscreenFirst,
    );
    final details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelSeedNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  /// 예약된 알림 ID 목록 (디버그 확인용, #244).
  /// 심기 직후 1002·2001~2004 등이 들어있는지 로그로 확인한다.
  /// 플랫폼 채널이라 테스트에서는 호출하지 않는다.
  Future<List<int>> pendingIds() async {
    try {
      final list = await _plugin.pendingNotificationRequests();
      return list.map((e) => e.id).toList();
    } catch (e) {
      debugPrint('pending lookup failed: $e');
      return const [];
    }
  }

  /// OS 알림 권한을 요청한다 (#244 후속).
  /// 매일 알림 스위치를 켤 때 호출한다. 앱을 껐다 켜도 시스템 설정에서
  /// 거부된 상태면 알림이 오지 않으므로, 켜는 시점에 권한을 요청한다.
  /// 하나라도 거부·실패하면 `false`를 돌려준다.
  Future<bool> requestPermissions() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidGranted = await android?.requestNotificationsPermission();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      // 해당 플랫폼이 아니면 null이므로, null은 통과로 본다.
      if (androidGranted == false || iosGranted == false) return false;
      return true;
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      return false;
    }
  }

  /// 기기 타임존을 `tz.local`에 반영한다 (#164).
  /// 조회 실패·미지원 이름이면 UTC 기본값을 유지하고 조용히 넘어간다.
  /// 앱 시작을 막지 않는 것이 우선이다 (`main()`의 try/catch와 동일 방침).
  @visibleForTesting
  static Future<void> configureLocalTimezone(
      {Future<String> Function()? provider}) async {
    try {
      final name = provider != null
          ? await provider()
          : (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('Local timezone setup failed, using UTC: $e');
    }
  }

  /// 씨앗 완성(열매) 1회 알림을 [completeAt]에 예약한다 (#140).
  /// 일일 알림과 같은 inexact 모드라 `SCHEDULE_EXACT_ALARM` 권한이 필요 없다.
  /// 이미 지난 시각이면 예약하지 않는다.
  Future<void> scheduleSeedCompleteNotification({
    required int id,
    required String title,
    required String body,
    required DateTime completeAt,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime.from(completeAt, tz.local);
    if (kDebugMode) {
      debugPrint('schedule check id=$id now=$now scheduled=$scheduled '
          'tz=${tz.local.name}');
    }
    if (!scheduled.isAfter(now)) {
      if (kDebugMode) {
        debugPrint('schedule skipped id=$id (not after now)');
      }
      return;
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
