import 'package:flutter_test/flutter_test.dart';
import 'package:malssi/core/services/live_activity_service.dart';

class FakeLiveActivityGateway implements LiveActivityGateway {
  var initialized = false;
  var enabled = true;
  var shouldThrow = false;
  final created = <String, Map<String, dynamic>>{};
  final ended = <String>[];

  @override
  Future<void> init({required String appGroupId}) async {
    initialized = true;
  }

  @override
  Future<bool> areEnabled() async => enabled;

  @override
  Future<void> createOrUpdate(
    String activityId,
    Map<String, dynamic> data, {
    Duration? staleIn,
  }) async {
    if (shouldThrow) throw StateError('activity unavailable');
    created[activityId] = data;
  }

  @override
  Future<void> end(String activityId) async {
    if (shouldThrow) throw StateError('activity unavailable');
    ended.add(activityId);
  }

  @override
  Future<void> endAll() async {
    if (shouldThrow) throw StateError('activity unavailable');
    for (final id in created.keys) {
      if (!ended.contains(id)) ended.add(id);
    }
  }
}

void main() {
  group('LiveActivityService (#248)', () {
    test('starts with seed type and stage data', () async {
      final gateway = FakeLiveActivityGateway();
      final service = LiveActivityService(gateway: gateway);

      await service.syncSeed(
        dateKey: '2030-01-01',
        quoteText: 't',
        status: 'growing',
        stage: 2,
        plantedAtIso: '2030-01-01T00:00:00.000Z',
        completeAtIso: '2030-01-01T08:00:00.000Z',
        themeLabel: '딸기',
        fruitEmoji: '🍓',
      );

      final data = gateway.created['growth-2030-01-01'];
      expect(data, isNotNull);
      expect(data!['status'], 'growing');
      expect(data['stage'], 2);
      expect(data['theme_label'], '딸기');
      expect(data['fruit_emoji'], '🍓');
      expect(data['planted_at'], isNonZero);
      expect(data['complete_at'], isNonZero);
    });

    test('starts immediately at stage 0 (#267)', () async {
      final gateway = FakeLiveActivityGateway();
      final service = LiveActivityService(gateway: gateway);

      await service.syncSeed(
        dateKey: '2030-01-01',
        quoteText: 't',
        status: 'growing',
        stage: 0,
        plantedAtIso: '2030-01-01T00:00:00.000Z',
        completeAtIso: '2030-01-01T10:00:00.000Z',
        themeLabel: '딸기',
        fruitEmoji: '🍓',
      );

      expect(gateway.created['growth-2030-01-01']!['stage'], 0);
    });

    test('same stage is not pushed twice', () async {
      final gateway = FakeLiveActivityGateway();
      final service = LiveActivityService(gateway: gateway);

      Future<void> sync() => service.syncSeed(
            dateKey: '2030-01-01',
            quoteText: 't',
            status: 'growing',
            stage: 2,
            completeAtIso: '2030-01-01T08:00:00.000Z',
          );

      await sync();
      gateway.created.clear();
      await sync();

      expect(gateway.created, isEmpty);
    });

    test('stage advance pushes again', () async {
      final gateway = FakeLiveActivityGateway();
      final service = LiveActivityService(gateway: gateway);

      Future<void> sync(int stage) => service.syncSeed(
            dateKey: '2030-01-01',
            quoteText: 't',
            status: 'growing',
            stage: stage,
            completeAtIso: '2030-01-01T08:00:00.000Z',
          );

      await sync(2);
      await sync(3);

      expect(gateway.created['growth-2030-01-01']!['stage'], 3);
    });

    test('keeps the activity and shows fruit on complete (#268)',
        () async {
      final gateway = FakeLiveActivityGateway();
      final service = LiveActivityService(gateway: gateway);

      await service.syncSeed(
        dateKey: '2030-01-01',
        quoteText: 't',
        status: 'growing',
        stage: 4,
        completeAtIso: '2030-01-01T08:00:00.000Z',
      );
      await service.syncSeed(
        dateKey: '2030-01-01',
        quoteText: 't',
        status: 'complete',
        stage: 5,
        themeLabel: '딸기',
        fruitEmoji: '🍓',
      );

      expect(gateway.ended, isEmpty);
      final data = gateway.created['growth-2030-01-01']!;
      expect(data['status'], 'complete');
      expect(data['stage'], 5);
      expect(data['fruit_emoji'], '🍓');
    });

    test('ends the previous day activity on date change', () async {
      final gateway = FakeLiveActivityGateway();
      final service = LiveActivityService(gateway: gateway);

      Future<void> sync(String date) => service.syncSeed(
            dateKey: date,
            quoteText: 't',
            status: 'growing',
            stage: 2,
            completeAtIso: '2030-01-01T08:00:00.000Z',
          );

      await sync('2030-01-01');
      await sync('2030-01-02');

      expect(gateway.ended, ['growth-2030-01-01']);
      expect(gateway.created['growth-2030-01-02'], isNotNull);
    });

    test('does not end what it did not start', () async {
      final gateway = FakeLiveActivityGateway();
      final service = LiveActivityService(gateway: gateway);

      await service.syncSeed(
        dateKey: '2030-01-01',
        quoteText: 't',
        status: 'locked',
        stage: 0,
      );

      expect(gateway.ended, isEmpty);
    });

    test('gateway failure does not throw', () async {
      final gateway = FakeLiveActivityGateway()..shouldThrow = true;
      final service = LiveActivityService(gateway: gateway);

      await service.syncSeed(
        dateKey: '2030-01-01',
        quoteText: 't',
        status: 'growing',
        stage: 2,
        completeAtIso: '2030-01-01T08:00:00.000Z',
      );
      await service.syncSeed(
        dateKey: '2030-01-01',
        quoteText: 't',
        status: 'complete',
        stage: 5,
      );
    });

    test('endAll stops everything and allows restart (#253 후속)', () async {
      final gateway = FakeLiveActivityGateway();
      final service = LiveActivityService(gateway: gateway);

      Future<void> grow() => service.syncSeed(
            dateKey: '2030-01-01',
            quoteText: 't',
            status: 'growing',
            stage: 2,
            completeAtIso: '2030-01-01T08:00:00.000Z',
          );
      await grow();
      expect(gateway.created['growth-2030-01-01'], isNotNull);

      // 전역 알림 off: 진행 중 알림 종료.
      await service.endAll();
      expect(gateway.ended, ['growth-2030-01-01']);

      // 다시 켜면 같은 단계라도 재시작된다 (키 초기화).
      await grow();
      expect(gateway.created['growth-2030-01-01'], isNotNull);
    });

    test('endAll clears activities from a previous session', () async {
      final gateway = FakeLiveActivityGateway();
      final first = LiveActivityService(gateway: gateway);
      await first.syncSeed(
        dateKey: '2030-01-01',
        quoteText: 't',
        status: 'complete',
        stage: 5,
      );

      // 앱을 재시작하면 세션 내 active 목록이 비어 있다.
      final second = LiveActivityService(gateway: gateway);
      await second.endAll();

      expect(gateway.ended, ['growth-2030-01-01']);
    });
  });
}
