import 'package:flutter_test/flutter_test.dart';
import 'package:malssi/core/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// #164 회귀 테스트: `tz.local`이 UTC 기본값에 머물면
/// 일일 알림 wall-clock이 UTC로 해석돼 KST 기준 9시간 어긋난다.
void main() {
  // `initializeTimeZones()`는 `tz.local`을 UTC로 되돌리므로
  // 각 테스트가 독립적인 초기 상태에서 시작한다.
  setUp(() => tz_data.initializeTimeZones());

  test('기기 타임존을 tz.local에 반영한다', () async {
    await NotificationService.configureLocalTimezone(
      provider: () async => 'Asia/Seoul',
    );

    expect(tz.local.name, 'Asia/Seoul');
  });

  test('서울 wall-clock 예약 시각에 +09:00 오프셋이 붙는다', () async {
    await NotificationService.configureLocalTimezone(
      provider: () async => 'Asia/Seoul',
    );

    // `scheduleDailySeedNotification`이 만드는 것과 같은 wall-clock 구성.
    final scheduled = tz.TZDateTime(tz.local, 2026, 9, 12, 7, 0);

    expect(scheduled.timeZoneOffset, const Duration(hours: 9));
    expect(scheduled.hour, 7);
  });

  test('타임존 조회에 실패해도 예외 없이 UTC 기본값을 유지한다', () async {
    await NotificationService.configureLocalTimezone(
      provider: () async => throw Exception('no platform plugin'),
    );

    expect(tz.local.name, 'Etc/UTC');
  });

  test('미지원 타임존 이름이어도 예외 없이 UTC 기본값을 유지한다', () async {
    await NotificationService.configureLocalTimezone(
      provider: () async => 'Not/AZone',
    );

    expect(tz.local.name, 'Etc/UTC');
  });
}
