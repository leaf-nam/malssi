import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/core/services/debug_clock.dart';
import 'package:malssi/core/services/debug_ui.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/widgets/word_wrap.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/data/seed_repository.dart';
import 'package:malssi/features/seed/domain/seed.dart';
import 'package:malssi/features/seed/presentation/seed_screen.dart';
import 'package:malssi/features/seed/providers/seed_providers.dart';

SeedProvider _buildProvider(
    {DateTime Function()? clock,
    String Function()? themePicker,
    ScheduleCompleteNotification? onSeedPlanted,
    CancelCompleteNotification? onSeedCompleted,
    ScheduleReminderNotification? onReminderDue}) {
  final seedRepository =
      InMemorySeedRepository(clock: clock, themePicker: themePicker);
  return SeedProvider(
    seedRepository: seedRepository,
    quoteRepository: InMemoryQuoteRepository(),
    fruitRepository: InMemoryFruitRepository(clock: clock),
    onSeedPlanted: onSeedPlanted,
    onSeedCompleted: onSeedCompleted,
    onReminderDue: onReminderDue,
  );
}

Widget _wrap(SeedProvider provider, {DebugUiProvider? debugUi}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: provider),
      ChangeNotifierProvider.value(value: debugUi ?? DebugUiProvider()),
    ],
    child: const MaterialApp(home: SeedScreen()),
  );
}

/// Firestore `Timestamp` 흉내. `fromMap`은 `createdAt.toDate()`를 호출하므로
/// 테스트에서도 같은 형태를 넘긴다 (실제 Firestore에서는 SDK가 변환).
class _FakeTimestamp {
  _FakeTimestamp(this._date);
  final DateTime _date;
  DateTime toDate() => _date;
}

void main() {
  // 공용 시계는 테스트 간에 새지 않게 매번 되돌린다 (#115).
  tearDown(DebugClock.reset);
  // 마감 규칙(#147) 탓에 실제 시각에 의존하면 오후에 깨지므로,
  // 공용 시계를 오전으로 고정한다. 개별 테스트의 shift는 누적된다.
  setUp(() {
    DebugClock.shift(DateTime(2026, 9, 4, 8).difference(DateTime.now()));
  });

  group('Seed model', () {
    test('dateKeyFor formats YYYY-MM-DD', () {
      expect(Seed.dateKeyFor(DateTime(2026, 9, 4)), '2026-09-04');
      expect(Seed.dateKeyFor(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('fromMap/toMap/copyWith round-trip', () {
      final seed = Seed(
        id: '2026-09-04',
        dateKey: '2026-09-04',
        quoteId: 'seed-1',
        status: SeedStatus.opened,
        createdAt: DateTime(2026, 9, 4),
        plantedAt: DateTime(2026, 9, 4),
      );
      final restored = Seed.fromMap(
          seed.toMap()
            ..['createdAt'] = _FakeTimestamp(seed.createdAt)
            ..['plantedAt'] = _FakeTimestamp(seed.plantedAt));

      expect(restored.id, seed.id);
      expect(restored.dateKey, seed.dateKey);
      expect(restored.quoteId, seed.quoteId);
      expect(restored.status, seed.status);
      expect(restored.isOpened, isTrue);
      expect(restored.isLocked, isFalse);
    });

    test('fromMap defaults a missing status to locked', () {
      final seed = Seed.fromMap({
        'id': 'x',
        'createdAt': _FakeTimestamp(DateTime(2026, 9, 4)),
      });

      expect(seed.status, SeedStatus.locked);
      expect(seed.isLocked, isTrue);
    });

    group('timeUntilNextStage (#138)', () {
      Seed growingAt(DateTime plantedAt) => Seed(
            id: '2026-09-04',
            dateKey: '2026-09-04',
            quoteId: 'seed-1',
            status: SeedStatus.growing,
            createdAt: plantedAt,
            plantedAt: plantedAt,
          );

      test('returns the remainder of the 2-hour stage', () {
        final seed = growingAt(DateTime(2026, 9, 4, 8));

        expect(seed.timeUntilNextStage(DateTime(2026, 9, 4, 9)),
            const Duration(hours: 1));
        expect(seed.timeUntilNextStage(DateTime(2026, 9, 4, 9, 37)),
            const Duration(minutes: 23));
      });

      test('resets to a full stage exactly on the boundary', () {
        final seed = growingAt(DateTime(2026, 9, 4, 8));

        expect(seed.timeUntilNextStage(DateTime(2026, 9, 4, 10)),
            const Duration(hours: 2));
      });

      test('returns zero when not growing or nearly complete', () {
        final plantedAt = DateTime(2026, 9, 4, 8);
        final locked = growingAt(plantedAt).copyWith(status: SeedStatus.locked);
        final complete =
            growingAt(plantedAt).copyWith(status: SeedStatus.complete);
        final growing = growingAt(plantedAt);

        expect(locked.timeUntilNextStage(DateTime(2026, 9, 4, 9)),
            Duration.zero);
        expect(complete.timeUntilNextStage(DateTime(2026, 9, 4, 9)),
            Duration.zero);
        // 5단계 도달(10시간 경과) = 완성 임박.
        expect(growing.timeUntilNextStage(DateTime(2026, 9, 4, 18)),
            Duration.zero);
      });
    });

    group('formatGrowthTimer (#138)', () {
      test('formats HH:MM with two digits', () {
        expect(formatGrowthTimer(const Duration(minutes: 83)), '01:23');
        expect(formatGrowthTimer(const Duration(hours: 2)), '02:00');
        expect(formatGrowthTimer(const Duration(minutes: 23)), '00:23');
      });

      test('rounds sub-minute up and hides zero', () {
        expect(formatGrowthTimer(const Duration(seconds: 30)), '00:01');
        expect(formatGrowthTimer(Duration.zero), isEmpty);
        expect(formatGrowthTimer(const Duration(seconds: -5)), isEmpty);
      });
    });

    group('noon deadline (#147)', () {
      Seed lockedAt(DateTime createdAt) => Seed(
            id: '2026-09-04',
            dateKey: '2026-09-04',
            quoteId: '',
            status: SeedStatus.locked,
            createdAt: createdAt,
            plantedAt: createdAt,
          );

      test('locked seed is missed after 14:00 on the same day', () {
        final seed = lockedAt(DateTime(2026, 9, 4, 8));

        expect(seed.isMissed(DateTime(2026, 9, 4, 8)), isFalse);
        expect(seed.isMissed(DateTime(2026, 9, 4, 13, 59)), isFalse);
        // 마감 정각까지는 심을 수 있다.
        expect(seed.isMissed(DateTime(2026, 9, 4, 14)), isFalse);
        expect(seed.isMissed(DateTime(2026, 9, 4, 14, 0, 1)), isTrue);
        expect(seed.isMissed(DateTime(2026, 9, 4, 23)), isTrue);
      });

      test('missed applies to locked seeds of the same day only', () {
        final growing =
            lockedAt(DateTime(2026, 9, 4, 8)).copyWith(status: SeedStatus.growing);
        final yesterday = Seed(
          id: '2026-09-03',
          dateKey: '2026-09-03',
          quoteId: '',
          status: SeedStatus.locked,
          createdAt: DateTime(2026, 9, 3, 8),
          plantedAt: DateTime(2026, 9, 3, 8),
        );

        expect(growing.isMissed(DateTime(2026, 9, 4, 15)), isFalse);
        expect(yesterday.isMissed(DateTime(2026, 9, 4, 15)), isFalse);
      });

      test('reminderAt is 13:00 of the given day', () {
        expect(Seed.reminderAt(DateTime(2026, 9, 4, 8)),
            DateTime(2026, 9, 4, 13));
      });
    });
  });

  group('InMemorySeedRepository', () {
    test('getTodaySeed creates a locked seed for today', () async {
      final repo =
          InMemorySeedRepository(clock: () => DateTime(2026, 9, 4, 12));

      final seed = await repo.getTodaySeed();

      expect(seed.id, '2026-09-04');
      expect(seed.isLocked, isTrue);
      expect(seed.quoteId, isEmpty);
    });

    test('openSeed links the quote and marks opened', () async {
      final repo =
          InMemorySeedRepository(clock: () => DateTime(2026, 9, 4, 12));
      final seed = await repo.getTodaySeed();
      final quote = Quote(
        id: 'seed-1',
        text: 't',
        author: 'a',
        likes: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      final opened =
          await repo.openSeed(seedId: seed.id, quote: quote);

      expect(opened.isOpened, isTrue);
      expect(opened.quoteId, 'seed-1');
    });

    test('openSeed twice throws', () async {
      final repo =
          InMemorySeedRepository(clock: () => DateTime(2026, 9, 4, 12));
      final seed = await repo.getTodaySeed();
      final quote = Quote(
        id: 'seed-1',
        text: 't',
        author: 'a',
        likes: 0,
        createdAt: DateTime(2026, 1, 1),
      );
      await repo.openSeed(seedId: seed.id, quote: quote);

      expect(
        () => repo.openSeed(seedId: seed.id, quote: quote),
        throwsStateError,
      );
    });

    test('unopened seed expires after midnight with no carryover', () async {
      var now = DateTime(2026, 9, 4, 23);
      final repo = InMemorySeedRepository(clock: () => now);
      await repo.getTodaySeed();

      now = DateTime(2026, 9, 5, 1);
      final next = await repo.getTodaySeed();
      final seeds = await repo.getSeedsStream().first;

      expect(next.id, '2026-09-05');
      expect(next.isLocked, isTrue);
      expect(
        seeds.firstWhere((s) => s.id == '2026-09-04').status,
        SeedStatus.expired,
      );
    });

    group('noon deadline (#147)', () {
      Quote testQuote() => Quote(
            id: 'seed-1',
            text: 't',
            author: 'a',
            likes: 0,
            createdAt: DateTime(2026, 1, 1),
          );

      test('today seed expires after 14:00 when unplanted', () async {
        final repo = InMemorySeedRepository(
            clock: () => DateTime(2026, 9, 4, 15));

        final seed = await repo.getTodaySeed();

        expect(seed.status, SeedStatus.expired);
      });

      test('planting after 14:00 throws', () async {
        var now = DateTime(2026, 9, 4, 8);
        final repo = InMemorySeedRepository(clock: () => now);
        final seed = await repo.getTodaySeed();

        now = DateTime(2026, 9, 4, 15);

        expect(
          () => repo.plantSeed(seedId: seed.id, quote: testQuote()),
          throwsStateError,
        );
      });

      test('planting at 14:00 sharp still works', () async {
        final repo = InMemorySeedRepository(
            clock: () => DateTime(2026, 9, 4, 14));
        final seed = await repo.getTodaySeed();

        final planted =
            await repo.plantSeed(seedId: seed.id, quote: testQuote());

        expect(planted.isGrowing, isTrue);
      });
    });

    test('getActiveSeed yields to today when completion is stale (#109)',
        () async {
      var now = DateTime(2026, 9, 4, 12);
      final repo = InMemorySeedRepository(clock: () => now);
      final seed = await repo.getTodaySeed();
      final quote = Quote(
        id: 'seed-1',
        text: 't',
        author: 'a',
        likes: 0,
        createdAt: DateTime(2026, 1, 1),
      );
      await repo.plantSeed(seedId: seed.id, quote: quote);
      await repo.debugFastForward(
          seedId: seed.id, by: const Duration(hours: 10));

      // 당일 완성이면 그대로 표시한다.
      expect((await repo.getActiveSeed()).isComplete, isTrue);

      // 날짜가 바뀌면 지난 완성은 오늘 씨앗에 양보한다.
      now = DateTime(2026, 9, 5, 12);
      final active = await repo.getActiveSeed();
      expect(active.id, '2026-09-05');
      expect(active.isLocked, isTrue);
    });
  });

  group('SeedProvider', () {
    test('plant then complete harvests a fruit and reveals the quote',
        () async {
      final seedRepository = InMemorySeedRepository(
          clock: () => DateTime(2026, 9, 4, 12));
      final fruitRepository = InMemoryFruitRepository(
          clock: () => DateTime(2026, 9, 4, 12));
      final provider = SeedProvider(
        seedRepository: seedRepository,
        quoteRepository: InMemoryQuoteRepository(),
        fruitRepository: fruitRepository,
      );

      await provider.ensureTodaySeed();
      expect(provider.todaySeed, isNotNull);
      expect(provider.revealedQuote, isNull);

      await provider.plantSeed();
      expect(provider.todaySeed!.isGrowing, isTrue);
      // #46: 심자마자 명언이 바로 공개된다.
      expect(provider.revealedQuote, isNotNull);

      for (var i = 0; i < 5; i++) {
        await provider.debugAdvanceGrowth();
      }
      expect(provider.todaySeed!.isComplete, isTrue);
      expect(provider.revealedQuote, isNotNull);
      expect(provider.errorMessage, isNull);

      final fruits = await fruitRepository.getFruits();
      expect(fruits.length, 1);
      expect(fruits.first.text, provider.revealedQuote!.text);
    });

    test('saveReview stores memo and score on the completed fruit',
        () async {
      final seedRepository = InMemorySeedRepository(
          clock: () => DateTime(2026, 9, 4, 12));
      final fruitRepository = InMemoryFruitRepository(
          clock: () => DateTime(2026, 9, 4, 12));
      final provider = SeedProvider(
        seedRepository: seedRepository,
        quoteRepository: InMemoryQuoteRepository(),
        fruitRepository: fruitRepository,
      );

      await provider.ensureTodaySeed();
      await provider.plantSeed();
      for (var i = 0; i < 5; i++) {
        await provider.debugAdvanceGrowth();
      }
      expect(provider.completedFruit, isNotNull);

      await provider.saveReview(memo: '잘 지켰다', fidelityScore: 5);

      expect(provider.completedFruit!.memo, '잘 지켰다');
      expect(provider.completedFruit!.fidelityScore, 5);
      expect(provider.errorMessage, isNull);
    });

    test('saveReview locks after the first save (#71)', () async {
      final provider = _buildProvider();

      await provider.ensureTodaySeed();
      await provider.plantSeed();
      await provider.debugCompleteNow();
      expect(provider.completedFruit, isNotNull);

      await provider.saveReview(memo: '첫 후기', fidelityScore: 4);
      expect(provider.completedFruit!.memo, '첫 후기');

      // 두 번째 저장은 무시된다 (수정 잠금).
      await provider.saveReview(memo: '바꾼 후기', fidelityScore: 1);
      expect(provider.completedFruit!.memo, '첫 후기');
      expect(provider.completedFruit!.fidelityScore, 4);
      expect(provider.errorMessage, isNull);
    });

    test('saveReview ignores an empty first save (#71)', () async {
      final provider = _buildProvider();

      await provider.ensureTodaySeed();
      await provider.plantSeed();
      await provider.debugCompleteNow();

      await provider.saveReview(memo: '', fidelityScore: 0);

      expect(provider.completedFruit!.isReviewed, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('debugAdvanceOneStage rises exactly one stage (#69)', () async {
      final provider = _buildProvider();

      await provider.ensureTodaySeed();
      await provider.plantSeed();
      expect(provider.todaySeed!.growthStage, 0);

      await provider.debugAdvanceOneStage();

      expect(provider.todaySeed!.isGrowing, isTrue);
      expect(provider.todaySeed!.growthStage, 1);
      expect(provider.errorMessage, isNull);
    });

    test('debugCompleteNow harvests immediately (#69)', () async {
      final provider = _buildProvider();

      await provider.ensureTodaySeed();
      await provider.plantSeed();
      expect(provider.todaySeed!.isGrowing, isTrue);

      await provider.debugCompleteNow();

      expect(provider.todaySeed!.isComplete, isTrue);
      expect(provider.revealedQuote, isNotNull);
      expect(provider.completedFruit, isNotNull);
      expect(provider.errorMessage, isNull);
    });

    test('a day passing expires locked seeds and creates a new one (#95)',
        () async {
      var now = DateTime(2026, 9, 4, 12);
      final provider = _buildProvider(clock: () => now);
      await provider.ensureTodaySeed();
      expect(provider.todaySeed!.id, '2026-09-04');

      // 하루가 지나면 만료되고 새 씨앗이 생긴다.
      now = now.add(const Duration(days: 1));
      await provider.refreshGrowth();

      expect(provider.todaySeed!.id, '2026-09-05');
      expect(provider.todaySeed!.isLocked, isTrue);
      expect(provider.errorMessage, isNull);
    });

    test('debugAdvanceDay moves the shared clock to a new seed (#115)',
        () async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();
      final before = provider.todaySeed!.id;

      await provider.debugAdvanceDay();

      expect(provider.todaySeed!.id, isNot(before));
      expect(provider.todaySeed!.isLocked, isTrue);
      expect(provider.errorMessage, isNull);
    });

    test('debugAdvanceHours grows the seed in small steps (#115)',
        () async {
      final provider =
          _buildProvider(themePicker: () => SeedTheme.vitality);
      await provider.ensureTodaySeed();
      await provider.plantSeed();
      final plantedId = provider.todaySeed!.id;

      await provider.debugAdvanceHours(1);
      expect(provider.todaySeed!.id, plantedId);
      expect(provider.todaySeed!.growthStage, 0);

      await provider.debugAdvanceHours(1);
      expect(provider.todaySeed!.id, plantedId);
      expect(provider.todaySeed!.growthStage, 1);
      expect(provider.errorMessage, isNull);
    });

    test('a day passing discards unreviewed stale completions (#113)',
        () async {
      var now = DateTime(2026, 9, 4, 12);
      final seedRepository = InMemorySeedRepository(
        clock: () => now,
        themePicker: () => SeedTheme.vitality,
      );
      final fruitRepository = InMemoryFruitRepository(clock: () => now);
      final provider = SeedProvider(
        seedRepository: seedRepository,
        quoteRepository: InMemoryQuoteRepository(),
        fruitRepository: fruitRepository,
      );
      await provider.ensureTodaySeed();
      await provider.plantSeed();

      now = now.add(const Duration(days: 1));
      await provider.refreshGrowth();

      // 일자 변경선: 지난 완성은 오늘 씨앗에 양보하고,
      // 미수확 이월분은 수확하지 않고 폐기한다.
      expect(provider.todaySeed!.id, '2026-09-05');
      expect(provider.todaySeed!.isLocked, isTrue);
      expect(await fruitRepository.getFruits(), isEmpty);
      expect(provider.errorMessage, isNull);
    });

    test('rollover prunes unreviewed fruits but keeps reviewed ones (#113)',
        () async {
      var now = DateTime(2026, 9, 4, 12);
      final seedRepository = InMemorySeedRepository(
        clock: () => now,
        themePicker: () => SeedTheme.vitality,
      );
      final fruitRepository = InMemoryFruitRepository(clock: () => now);
      final provider = SeedProvider(
        seedRepository: seedRepository,
        quoteRepository: InMemoryQuoteRepository(),
        fruitRepository: fruitRepository,
      );
      await provider.ensureTodaySeed();
      await provider.plantSeed();
      await provider.debugCompleteNow();
      expect(provider.todaySeed!.isComplete, isTrue);
      expect(provider.completedFruit, isNotNull);

      // 후기 없이 날짜가 바뀌면 미후기 열매는 폐기된다.
      now = now.add(const Duration(days: 1));
      await provider.refreshGrowth();

      expect(provider.todaySeed!.id, '2026-09-05');
      expect(provider.todaySeed!.isLocked, isTrue);
      expect(await fruitRepository.getFruits(), isEmpty);
      expect(provider.errorMessage, isNull);
    });

    test('reviewed fruits survive the rollover (#113)', () async {
      var now = DateTime(2026, 9, 4, 12);
      final seedRepository = InMemorySeedRepository(
        clock: () => now,
        themePicker: () => SeedTheme.vitality,
      );
      final fruitRepository = InMemoryFruitRepository(clock: () => now);
      final provider = SeedProvider(
        seedRepository: seedRepository,
        quoteRepository: InMemoryQuoteRepository(),
        fruitRepository: fruitRepository,
      );
      await provider.ensureTodaySeed();
      await provider.plantSeed();
      await provider.debugCompleteNow();
      await provider.saveReview(memo: '잘 지켰다', fidelityScore: 5);

      now = now.add(const Duration(days: 1));
      await provider.refreshGrowth();

      // 후기를 남긴 열매는 이월 후에도 보관에 남는다.
      expect(provider.todaySeed!.id, '2026-09-05');
      expect(provider.todaySeed!.isLocked, isTrue);
      final fruits = await fruitRepository.getFruits();
      expect(fruits.length, 1);
      expect(fruits.single.seedId, '2026-09-04');
      expect(fruits.single.isReviewed, isTrue);
      expect(provider.errorMessage, isNull);
    });

    group('completion notification callbacks (#140)', () {
      test('planting schedules completion 10 hours later', () async {
        final plantedAt = DateTime(2026, 9, 4, 8);
        DateTime? scheduledAt;
        final provider = _buildProvider(
          clock: () => plantedAt,
          onSeedPlanted: ({required completeAt}) async {
            scheduledAt = completeAt;
          },
        );
        await provider.ensureTodaySeed();
        await provider.plantSeed();

        expect(provider.todaySeed!.isGrowing, isTrue);
        expect(scheduledAt, plantedAt.add(const Duration(hours: 10)));
        expect(provider.errorMessage, isNull);
      });

      test('harvest cancels the scheduled completion', () async {
        var completedCalls = 0;
        final provider = _buildProvider(
          clock: () => DateTime(2026, 9, 4, 8),
          onSeedCompleted: () async {
            completedCalls++;
          },
        );
        await provider.ensureTodaySeed();
        await provider.plantSeed();
        await provider.debugCompleteNow();

        expect(provider.todaySeed!.isComplete, isTrue);
        expect(completedCalls, 1);
        expect(provider.errorMessage, isNull);
      });

      test('restart with a growing seed reschedules completion', () async {
        final clockTime = DateTime(2026, 9, 4, 8);
        final seedRepository = InMemorySeedRepository(
          clock: () => clockTime,
          themePicker: () => SeedTheme.vitality,
        );
        final fruitRepository = InMemoryFruitRepository(
          clock: () => clockTime,
        );
        final first = SeedProvider(
          seedRepository: seedRepository,
          quoteRepository: InMemoryQuoteRepository(),
          fruitRepository: fruitRepository,
        );
        await first.ensureTodaySeed();
        await first.plantSeed();

        DateTime? rescheduledAt;
        final restarted = SeedProvider(
          seedRepository: seedRepository,
          quoteRepository: InMemoryQuoteRepository(),
          fruitRepository: fruitRepository,
          onSeedPlanted: ({required completeAt}) async {
            rescheduledAt = completeAt;
          },
        );
        await restarted.ensureTodaySeed();

        expect(restarted.todaySeed!.isGrowing, isTrue);
        expect(rescheduledAt, clockTime.add(const Duration(hours: 10)));
        expect(restarted.errorMessage, isNull);
      });
    });

    group('deadline reminder callbacks (#147)', () {
      test('locked seed requests a reminder for 13:00', () async {
        DateTime? requestedAt;
        final provider = _buildProvider(
          clock: () => DateTime(2026, 9, 4, 8),
          onReminderDue: ({required reminderAt}) async {
            requestedAt = reminderAt;
          },
        );
        await provider.ensureTodaySeed();

        expect(provider.todaySeed!.isLocked, isTrue);
        expect(requestedAt, DateTime(2026, 9, 4, 13));
        expect(provider.errorMessage, isNull);
      });

      test('no reminder once growing or missed', () async {
        var calls = 0;
        final provider = _buildProvider(
          clock: () => DateTime(2026, 9, 4, 8),
          onReminderDue: ({required reminderAt}) async {
            calls++;
          },
        );
        await provider.ensureTodaySeed();
        await provider.plantSeed();
        expect(calls, 1);

        // 성장 중에는 다시 요청하지 않는다.
        await provider.ensureTodaySeed();
        expect(calls, 1);

        // 마감된 씨앗에도 요청하지 않는다.
        final missed = _buildProvider(
          clock: () => DateTime(2026, 9, 4, 15),
          onReminderDue: ({required reminderAt}) async {
            calls++;
          },
        );
        await missed.ensureTodaySeed();
        expect(missed.todaySeed!.status, SeedStatus.expired);
        expect(calls, 1);
      });
    });
  });

  group('SeedScreen', () {
    testWidgets('entering the tab refreshes growth state (#62)',
        (tester) async {
      // 사전 준비 없이 진입 → 화면이 직접 갱신해 씨앗을 준비한다.
      final provider = _buildProvider();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('씨앗 심기'), findsOneWidget);
    });

    testWidgets('locked seed shows the plant button', (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('씨앗 심기'), findsOneWidget);
      // #59: 말씨 탭 배경은 니어블랙 고정.
      // (하단 바는 셸이 상주로 들고 있어 화면 트리에 없음, #79.)
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppTheme.abyss);
    });

    testWidgets('missed seed shows the deadline notice (#147)',
        (tester) async {
      final provider =
          _buildProvider(clock: () => DateTime(2026, 9, 4, 15));
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(provider.todaySeed!.status, SeedStatus.expired);
      expect(find.text('오늘의 씨앗이 마감되었어요'), findsOneWidget);
      // 마감 후에는 심기 버튼을 보여주지 않는다.
      expect(find.text('씨앗 심기'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('debug reset wipes seeds and restarts the morning',
        (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();
      await provider.plantSeed();
      expect(provider.todaySeed!.isGrowing, isTrue);

      await provider.debugResetAllSeeds();

      // 심기 전 잠금 씨앗으로 돌아오고 시계는 오늘 아침 8시다.
      expect(provider.todaySeed!.isLocked, isTrue);
      expect(provider.revealedQuote, isNull);
      final now = DebugClock.now();
      expect(now.hour, 8);
      final seeds = provider.todaySeed!;
      expect(seeds.dateKey, Seed.dateKeyFor(now));
    });

    testWidgets('reset button restores the plant screen', (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();
      await provider.plantSeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.text('디버그: 씨앗 초기화'));
      await tester.pumpAndSettle();

      expect(provider.todaySeed!.isLocked, isTrue);
      expect(find.text('씨앗 심기'), findsOneWidget);
    });

    testWidgets('debug clock shows up and follows time buttons',
        (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 공용 시계(고정 오전)와 같은 시각이 보인다.
      // (핀 고정 자체가 shift라 suffix가 붙을 수 있어 prefix로 본다.)
      expect(find.textContaining('⏰ 09-04 08:00'), findsOneWidget);

      await tester.tap(find.text('디버그: +1시간'));
      await tester.pumpAndSettle();

      // 버튼 효과(시각 이동 + 이동량)가 바로 보인다.
      expect(find.textContaining('⏰ 09-04 09:00'), findsOneWidget);
      final off = DebugClock.offset.inHours;
      expect(find.textContaining('($off h)'), findsOneWidget);
    });

    testWidgets('expired seed still responds to time buttons',
        (tester) async {
      // 저장소 시계는 15시에 고정하고 공용 시계만 움직인다.
      // 씨앗 상태는 그대로여도 시각 표시는 바뀌어야 한다.
      final provider =
          _buildProvider(clock: () => DateTime(2026, 9, 4, 15));
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.textContaining('⏰ 09-04 08:00'), findsOneWidget);

      await tester.tap(find.text('디버그: +1시간'));
      await tester.pumpAndSettle();

      expect(provider.todaySeed!.status, SeedStatus.expired);
      expect(find.textContaining('⏰ 09-04 09:00'), findsOneWidget);
    });

    testWidgets('locked seed centers the date below the title (#163)',
        (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 날짜가 이미지 아래·버튼 위 중앙 클러스터에 있다.
      final dateDy = tester.getCenter(find.text('2026-09-04')).dy;
      final imageDy = tester.getCenter(find.byType(Image)).dy;
      final buttonDy = tester.getCenter(find.text('씨앗 심기')).dy;
      expect(dateDy, greaterThan(imageDy));
      expect(dateDy, lessThan(buttonDy));
    });

    testWidgets('locked seed shows the 2PM cutoff notice (#161)',
        (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('씨앗은 2시까지만 받을 수 있어요!'), findsOneWidget);
      expect(find.text('씨앗 심기'), findsOneWidget);
    });

    testWidgets('dot images use nearest-neighbor filtering (#160)',
        (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 심기 전 씨앗 이미지.
      expect(
        tester.widget<Image>(find.byType(Image)).filterQuality,
        FilterQuality.none,
      );
      // #160: 75px 소스의 정수배(1x)로 표시한다.
      expect(tester.widget<Image>(find.byType(Image)).width, 75);

      // 성장 중 에셋 이미지.
      await provider.plantSeed();
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsWidgets);
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        expect(image.filterQuality, FilterQuality.none);
      }
      // #160: 170px 소스의 정수배(2x = 340)까지만 키운다.
      expect(
        find.byWidgetPredicate((w) =>
            w is ConstrainedBox && w.constraints.maxWidth == 340),
        findsOneWidget,
      );
    });

    testWidgets('growth timer sits centered above the asset (#163)',
        (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();
      await provider.plantSeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 타이머가 에셋보다 위에, 화면 중앙대에 있다.
      final labelDy = tester.getCenter(find.text('다음 성장까지')).dy;
      final imageDy = tester.getCenter(find.byType(Image)).dy;
      expect(labelDy, lessThan(imageDy));
      final height = tester.view.physicalSize.height /
          tester.view.devicePixelRatio;
      expect(labelDy,
          inInclusiveRange(height * 0.25, height * 0.75));
    });

    testWidgets('missed seed hides the 2PM cutoff notice (#161)',
        (tester) async {
      final provider =
          _buildProvider(clock: () => DateTime(2026, 9, 4, 15));
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('오늘의 씨앗이 마감되었어요'), findsOneWidget);
      expect(find.text('씨앗은 2시까지만 받을 수 있어요!'), findsNothing);
    });

    testWidgets('completed seed advances to the next day (#109)',
        (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();
      await provider.plantSeed();
      await provider.debugCompleteNow();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 완성 화면에도 디버그 날짜 이동이 있다.
      expect(find.text('디버그: +1일'), findsOneWidget);

      // 완성 상태에서 +1일을 누르면 다음 날 새 씨앗(심기 전)이 보인다.
      await tester.tap(find.text('디버그: +1일'));
      await tester.pumpAndSettle();

      expect(find.text('씨앗 심기'), findsOneWidget);
    });

    testWidgets('tab switch blends the bar color without sliding (#77)',
        (tester) async {
      Color barColor() {
        final box = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(AnimatedContainer),
            matching: find.byType(DecoratedBox),
          ),
        );
        return (box.decoration as BoxDecoration).color!;
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MainBottomNav(currentIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(barColor(), AppTheme.abyss);

      // 탭 전환 → 애니메이션 중간에는 양쪽 끝색과 다른 보간색이다.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MainBottomNav(currentIndex: 1),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 125));

      final mid = barColor();
      expect(mid, isNot(AppTheme.abyss));
      expect(mid, isNot(AppTheme.navGardenLight));

      await tester.pumpAndSettle();
      expect(barColor(), AppTheme.navGardenLight);
    });

    testWidgets('tab bar top padding is painted with the tab color (#81)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MainBottomNav(currentIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 상단 패딩이 색상 컨테이너 안에 있어야 배경 노출 줄이 생기지 않는다.
      expect(
        find.descendant(
          of: find.byType(AnimatedContainer),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Padding &&
                w.padding == const EdgeInsets.only(top: 8),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('plant reveals the quote at once with growth below',
        (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.text('씨앗 심기'));
      await tester.pumpAndSettle();

      expect(find.text('씨앗 심기'), findsNothing);
      // #46: 심자마자 명언이 보이고, 그 아래 성장 에셋이 그려진다.
      expect(provider.revealedQuote, isNotNull);
      expect(find.textContaining(keepWordsTogether(provider.revealedQuote!.text)),
          findsOneWidget);
      // #57: 성장 형태(에셋)만 보이고 단계·안내 문구는 없다.
      expect(find.textContaining('단계 성장 중'), findsNothing);
      expect(find.textContaining('2시간마다'), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      // #163에서 명언·에셋 1:1 + 가운데 타이머로 변경 (종전 6:4).
      final growingFlexes = tester
          .widgetList<Expanded>(find.byType(Expanded))
          .map((e) => e.flex)
          .toList();
      expect(growingFlexes[0], 1);
      expect(growingFlexes[1], 1);

      // #64: 디버그 5초 간격이라 +1단계는 1단계만 오른다.
      await tester.tap(find.text('디버그: +1단계'));
      await tester.pumpAndSettle();

      expect(provider.todaySeed!.isGrowing, isTrue);
      expect(provider.todaySeed!.growthStage, 1);

      // #69: 열매 만들기는 남은 단계 전부 진행해 즉시 완성한다.
      await tester.tap(find.text('디버그: 열매 만들기'));
      await tester.pumpAndSettle();

      expect(provider.todaySeed!.isComplete, isTrue);
      expect(find.textContaining(keepWordsTogether(provider.revealedQuote!.text)),
          findsOneWidget);
    });

    testWidgets('growing seed shows the timer below, completion hides it (#138)',
        (tester) async {
      // 심은 지 61분째: 라벨 + 타이머가 씨앗 아래에 보인다.
      // (공용 시계 고정 08:00 기준.)
      final plantedBase = DateTime(2026, 9, 4, 7);
      final provider = _buildProvider(clock: () => plantedBase);
      await provider.ensureTodaySeed();
      await provider.plantSeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(provider.todaySeed!.isGrowing, isTrue);
      expect(find.text('다음 성장까지'), findsOneWidget);
      expect(
          find.textContaining(RegExp(r'^\d\d:\d\d$')), findsOneWidget);

      // 완성되면 타이머 대신 완성 화면이 보인다.
      await tester.tap(find.text('디버그: 열매 만들기'));
      await tester.pumpAndSettle();

      expect(provider.todaySeed!.isComplete, isTrue);
      expect(find.text('다음 성장까지'), findsNothing);
      expect(find.textContaining(RegExp(r'^\d\d:\d\d$')), findsNothing);
      expect(find.text('열매가 완성되었어요'), findsNothing);
    });

    testWidgets('final stage shows only the completion phrase (#138)',
        (tester) async {
      // 저장소 시각은 심은 직후로 고정하고, 공용 시계만 완성 단계로 미룬다.
      // (공용 시계 고정 08:00에서 +10시간.)
      final plantedBase = DateTime(2026, 9, 4, 8);
      final provider = _buildProvider(clock: () => plantedBase);
      await provider.ensureTodaySeed();
      await provider.plantSeed();
      DebugClock.shift(const Duration(hours: 10));

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 아직 수확 전(성장 중)이지만 남은시간은 0 → 문구만 남는다.
      expect(provider.todaySeed!.isGrowing, isTrue);
      expect(find.text('열매가 완성되었어요'), findsOneWidget);
      expect(find.text('다음 성장까지'), findsNothing);
      expect(find.textContaining(RegExp(r'^\d\d:\d\d$')), findsNothing);
    });

    testWidgets('locked screen advances the day (#95)', (tester) async {
      // 공용 시계 기반: 버튼이 앱 날짜를 직접 미룬다 (#115).
      final provider = _buildProvider();
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      final before = provider.todaySeed!.id;
      expect(find.text(before), findsOneWidget);

      await tester.tap(find.text('디버그: +1일'));
      await tester.pumpAndSettle();

      expect(provider.todaySeed!.id, isNot(before));
      expect(provider.todaySeed!.isLocked, isTrue);
      expect(find.text('씨앗 심기'), findsOneWidget);
    });

    testWidgets('advancing the day rolls over to a new seed (#109)',
        (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.text('씨앗 심기'));
      await tester.pumpAndSettle();
      final plantedId = provider.todaySeed!.id;

      await tester.tap(find.text('디버그: +1일'));
      await tester.pumpAndSettle();

      // 일자 변경선: 지난 완성은 오늘 씨앗에 양보해 새 잠금 씨앗이 보인다.
      expect(provider.todaySeed!.id, isNot(plantedId));
      expect(provider.todaySeed!.isLocked, isTrue);
      expect(find.text('씨앗 심기'), findsOneWidget);
    });

    testWidgets('advancing hours grows the seed step by step (#115)',
        (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.text('씨앗 심기'));
      await tester.pumpAndSettle();
      expect(provider.todaySeed!.growthStage, 0);

      await tester.tap(find.text('디버그: +1시간'));
      await tester.pumpAndSettle();
      expect(provider.todaySeed!.growthStage, 0);

      await tester.tap(find.text('디버그: +1시간'));
      await tester.pumpAndSettle();
      expect(provider.todaySeed!.growthStage, 1);
    });

    testWidgets('growing quote shows its source on demand (#123)',
        (tester) async {
      final quote = Quote(
        id: 'q-source',
        text: '시간을 아껴라',
        author: '작자',
        likes: 0,
        createdAt: DateTime(2026, 1, 1),
        theme: SeedTheme.growth,
        source: '한국어 위키인용집 (CC BY-SA 4.0)',
      );
      final provider = SeedProvider(
        seedRepository: InMemorySeedRepository(
            themePicker: () => SeedTheme.growth),
        quoteRepository: InMemoryQuoteRepository(seed: [quote]),
        fruitRepository: InMemoryFruitRepository(),
      );
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.text('씨앗 심기'));
      await tester.pumpAndSettle();

      // 출처가 있는 명언에만 출처 버튼이 있다.
      await tester.tap(find.text('출처'));
      await tester.pumpAndSettle();

      expect(find.text('명언 출처'), findsOneWidget);
      expect(find.text('한국어 위키인용집 (CC BY-SA 4.0)'),
          findsOneWidget);
    });

    testWidgets('quote without source hides the source button (#123)',
        (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.text('씨앗 심기'));
      await tester.pumpAndSettle();

      // 기본 7시드에는 출처가 없어 버튼이 없다.
      expect(find.text('출처'), findsNothing);
    });

    testWidgets('locked seed shows the themed seed image', (tester) async {
      final provider =
          _buildProvider(themePicker: () => SeedTheme.growth);
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('성장 씨앗이 도착했어요'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('completed quote is minimal: no tags, header, or guide',
        (tester) async {
      final provider =
          _buildProvider(themePicker: () => SeedTheme.growth);
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.text('씨앗 심기'));
      await tester.pumpAndSettle();
      // #69: 열매 만들기로 즉시 완성한다.
      await tester.tap(find.text('디버그: 열매 만들기'));
      await tester.pumpAndSettle();

      // 완성 화면에는 태그·안내 문구를 노출하지 않는다.
      expect(find.textContaining('#'), findsNothing);
      expect(find.textContaining('열매'), findsNothing);
      expect(find.textContaining('보관 탭에서'), findsNothing);
      expect(find.text('— 노자'), findsOneWidget);
      // #51: 완성 시 명언과 함께 열매 이미지가 나온다 (명언 2/3 : 열매 1/3).
      expect(find.byType(Image), findsOneWidget);
      final completedFlexes = tester
          .widgetList<Expanded>(find.byType(Expanded))
          .map((e) => e.flex)
          .toList();
      expect(completedFlexes[0], 2);
      expect(completedFlexes[1], 1);
    });

    testWidgets('tapping the completed quote opens the review sheet',
        (tester) async {
      final provider =
          _buildProvider(themePicker: () => SeedTheme.growth);
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.text('씨앗 심기'));
      await tester.pumpAndSettle();
      // #69: 열매 만들기로 즉시 완성한다.
      await tester.tap(find.text('디버그: 열매 만들기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('— 노자'));
      await tester.pumpAndSettle();

      expect(find.text('오늘의 점수'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '오늘 잘 지켰다');
      await tester.tap(find.byKey(const ValueKey('score-5')));
      await tester.pump();
      await tester.tap(find.text('후기 저장하기'));
      await tester.pumpAndSettle();

      expect(provider.completedFruit!.memo, '오늘 잘 지켰다');
      expect(provider.completedFruit!.fidelityScore, 5);
      expect(find.text('후기 저장하기'), findsNothing);

      // #71: 저장 후에는 읽기만 된다.
      expect(find.text('눌러서 오늘의 리뷰 보기'), findsOneWidget);
      await tester.tap(find.text('— 노자'));
      await tester.pumpAndSettle();

      expect(find.text('오늘 잘 지켰다'), findsOneWidget);
      expect(find.text('후기 저장하기'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
