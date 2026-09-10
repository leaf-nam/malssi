import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init({void Function()? onTap}) async {
    tz_data.initializeTimeZones();
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
  Future<void> scheduleDailySeedNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

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
    if (!scheduled.isAfter(now)) return;

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
