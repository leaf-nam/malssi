import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/core/services/debug_clock.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/widgets/word_wrap.dart';
import 'package:malssi/core/theme/theme_assets.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/archive/presentation/archive_screen.dart';
import 'package:malssi/features/archive/presentation/fruit_rain.dart';
import 'package:malssi/features/archive/presentation/fruit_review_sheet.dart';
import 'package:malssi/features/archive/providers/archive_providers.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/data/seed_repository.dart';
import 'package:malssi/features/seed/domain/seed.dart';
import 'package:malssi/features/seed/providers/seed_providers.dart';
import 'package:malssi/features/settings/data/settings_repository.dart';
import 'package:malssi/features/settings/providers/settings_providers.dart';

/// #108: 정원 화면은 열매 비 on/off 설정을 함께 본다.
/// [settings]를 주지 않으면 미로드 상태(기본값 on) provider를 쓴다.
/// #117: 오늘 테두리에 오늘 씨앗 테마를 함께 본다.
/// [seed]를 주지 않으면 미로드 상태(금색 폴백) provider를 쓴다.
Widget _wrap(ArchiveProvider provider,
    {SettingsProvider? settings, SeedProvider? seed}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: provider),
      ChangeNotifierProvider.value(
        value: settings ??
            SettingsProvider(
              settingsRepository: InMemorySettingsRepository(),
            ),
      ),
      ChangeNotifierProvider.value(
        value: seed ??
            SeedProvider(
              seedRepository: InMemorySeedRepository(),
              quoteRepository: InMemoryQuoteRepository(),
              fruitRepository: InMemoryFruitRepository(),
            ),
      ),
    ],
    // 열매 비 애니메이션을 멈춰 pumpAndSettle이 끝나게 한다 (#89).
    child: const TickerMode(
      enabled: false,
      child: MaterialApp(home: ArchiveScreen()),
    ),
  );
}

Future<void> _harvest(
  InMemoryFruitRepository repo, {
  required String seedId,
  required String text,
  required DateTime at,
  String theme = '',
  String source = '',
}) {
  return repo.harvestFromSeed(
    seed: Seed(
      id: seedId,
      dateKey: seedId,
      quoteId: 'q',
      status: SeedStatus.opened,
      createdAt: at,
      theme: theme,
      plantedAt: at,
    ),
    quote: Quote(
      id: 'q',
      text: text,
      author: '작자',
      likes: 0,
      createdAt: at,
      theme: theme,
      source: source,
    ),
  );
}

void main() {
  // 공용 시계는 테스트 간에 새지 않게 매번 되돌린다 (#115).
  tearDown(() {
    DebugClock.reset();
    ArchiveScreen.debugToday = null;
    // #195: 심김 모션 재생 기억을 비운다.
    PlantCell.debugReset();
  });

  group('Fruit model', () {
    test('fromMap/toMap/copyWith round-trip', () {
      final fruit = Fruit(
        id: 'fruit-2026-09-04',
        seedId: '2026-09-04',
        quoteId: 'seed-1',
        text: '시작이 반이다.',
        author: '한국 속담',
        harvestedAt: DateTime(2026, 9, 4, 12),
        memo: '잘 살았다',
        fidelityScore: 4,
      );
      final restored = Fruit.fromMap(
          fruit.toMap()..['harvestedAt'] = _FakeTimestamp());

      expect(restored.id, fruit.id);
      expect(restored.seedId, fruit.seedId);
      expect(restored.text, fruit.text);
      expect(restored.author, fruit.author);
      expect(restored.memo, '잘 살았다');
      expect(restored.fidelityScore, 4);
    });

    test('fromMap defaults review fields', () {
      final fruit = Fruit.fromMap({
        'id': 'x',
        'harvestedAt': _FakeTimestamp(),
      });

      expect(fruit.memo, isEmpty);
      expect(fruit.fidelityScore, 0);
    });

    test('harvestFromSeed snapshots the explanation (#216)', () async {
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      final fruit = await repo.harvestFromSeed(
        seed: Seed(
          id: '2026-09-04',
          dateKey: '2026-09-04',
          quoteId: 'q',
          status: SeedStatus.opened,
          createdAt: at,
          plantedAt: at,
        ),
        quote: Quote(
          id: 'q',
          text: '아는 것이 힘이다.',
          author: '프랜시스 베이컨',
          likes: 0,
          createdAt: at,
          theme: SeedTheme.wisdom,
          source: '한국어 위키인용집 (CC BY-SA 4.0)',
          explanation: '배우는 게 자신을 강하게 만들어요.',
        ),
      );

      expect(fruit.explanation, '배우는 게 자신을 강하게 만들어요.');
      // 스냅샷이라 원천이 바뀌어도 보관본은 유지된다.
      final restored = Fruit.fromMap(
          fruit.toMap()..['harvestedAt'] = _FakeTimestamp());
      expect(restored.explanation, '배우는 게 자신을 강하게 만들어요.');
      // 구 데이터 호환: 미기재 시 빈값.
      expect(Fruit.fromMap({'id': 'x', 'harvestedAt': _FakeTimestamp()}).explanation, '');
    });

    test('harvestDateKey formats YYYY-MM-DD', () {
      final fruit = Fruit(
        id: 'x',
        seedId: 'y',
        quoteId: 'q',
        text: 't',
        author: 'a',
        harvestedAt: DateTime(2026, 9, 4, 23, 30),
      );

      expect(fruit.harvestDateKey, '2026-09-04');
    });

    test('isReviewed needs memo or score (#65)', () {
      final at = DateTime(2026, 9, 4, 12);
      Fruit fruit({
        required String memo,
        required int fidelityScore,
      }) =>
          Fruit(
            id: 'x',
            seedId: 'y',
            quoteId: 'q',
            text: 't',
            author: 'a',
            harvestedAt: at,
            memo: memo,
            fidelityScore: fidelityScore,
          );

      expect(
          fruit(memo: '', fidelityScore: 0).isReviewed, isFalse);
      expect(
          fruit(memo: '잘 살았다', fidelityScore: 0).isReviewed,
          isTrue);
      expect(
          fruit(memo: '', fidelityScore: 4).isReviewed, isTrue);
    });
  });

  group('InMemoryFruitRepository review', () {
    test('updateReview stores memo and score', () async {
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo, seedId: '2026-09-04', text: 't', at: at);

      final updated = await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '충실했다',
        fidelityScore: 5,
      );

      expect(updated.memo, '충실했다');
      expect(updated.fidelityScore, 5);
      final fruits = await repo.getFruits();
      expect(fruits.single.memo, '충실했다');
    });

    test('updateReview rejects out-of-range scores', () async {
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo, seedId: '2026-09-04', text: 't', at: at);

      expect(
        () => repo.updateReview(
            fruitId: 'fruit-2026-09-04', memo: '', fidelityScore: 6),
        throwsArgumentError,
      );
      expect(
        () => repo.updateReview(
            fruitId: 'missing', memo: '', fidelityScore: 3),
        throwsStateError,
      );
    });

    test('pruneUnreviewedBeforeToday keeps reviewed and today (#113)',
        () async {
      var now = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => now);
      await _harvest(repo,
          seedId: '2026-09-04', text: '어제 미후기', at: now);
      await _harvest(repo,
          seedId: '2026-09-04-reviewed', text: '어제 후기', at: now);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04-reviewed',
        memo: '좋았다',
        fidelityScore: 4,
      );

      now = DateTime(2026, 9, 5, 12);
      await _harvest(repo,
          seedId: '2026-09-05', text: '오늘 미후기', at: now);

      await repo.pruneUnreviewedBeforeToday();

      final ids =
          (await repo.getFruits()).map((fruit) => fruit.id);
      expect(ids, contains('fruit-2026-09-04-reviewed'));
      expect(ids, contains('fruit-2026-09-05'));
      expect(ids, isNot(contains('fruit-2026-09-04')));
    });
  });

  group('ArchiveProvider', () {
    test('load exposes fruits newest first', () async {
      var now = DateTime(2026, 9, 3, 12);
      final repo = InMemoryFruitRepository(clock: () => now);
      await _harvest(repo, seedId: '2026-09-03', text: '어제', at: now);
      now = DateTime(2026, 9, 4, 12);
      await _harvest(repo, seedId: '2026-09-04', text: '오늘', at: now);

      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      expect(provider.fruits.length, 2);
      expect(provider.fruits.first.text, '오늘');
      expect(provider.fruits.last.text, '어제');
      expect(provider.errorMessage, isNull);
    });

    test('fruitsByDateKey maps date keys to fruits', () async {
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo, seedId: '2026-09-04', text: '오늘', at: at);

      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      expect(provider.fruitsByDateKey['2026-09-04']!.text, '오늘');
    });

    test('updateReview refreshes the list', () async {
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo, seedId: '2026-09-04', text: '오늘', at: at);

      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();
      await provider.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );

      expect(provider.fruits.single.memo, '좋았다');
      expect(provider.fruits.single.fidelityScore, 4);
      expect(provider.errorMessage, isNull);
    });

    test('plantedFruits only includes reviewed fruits (#65)', () async {
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo, seedId: '2026-09-03', text: '어제', at: at);
      await _harvest(repo, seedId: '2026-09-04', text: '오늘', at: at);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );

      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      expect(provider.fruits.length, 2);
      expect(provider.plantedFruits.length, 1);
      expect(provider.plantedFruits.single.text, '오늘');
      expect(
          provider.plantedByDateKey['2026-09-04']!.text, '오늘');
      expect(provider.plantedByDateKey.containsKey('2026-09-03'),
          isFalse);
    });

    test('themeCounts groups planted fruits with topTheme first (#88)',
        () async {
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-02',
          text: '이틀 전',
          at: at,
          theme: SeedTheme.growth);
      await _harvest(repo,
          seedId: '2026-09-03',
          text: '어제',
          at: at,
          theme: SeedTheme.vitality);
      await _harvest(repo,
          seedId: '2026-09-04',
          text: '오늘',
          at: at,
          theme: SeedTheme.growth);
      // 미후기 1개는 집계에서 제외된다.
      await _harvest(repo,
          seedId: '2026-09-05', text: '내일', at: at, theme: SeedTheme.peace);
      for (final id in ['2026-09-02', '2026-09-03', '2026-09-04']) {
        await repo.updateReview(
          fruitId: 'fruit-$id',
          memo: '좋았다',
          fidelityScore: 4,
        );
      }

      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      expect(provider.themeCounts,
          {SeedTheme.growth: 2, SeedTheme.vitality: 1});
      expect(provider.topTheme, SeedTheme.growth);
    });

    test('topTheme is empty without planted fruits (#88)', () async {
      final provider = ArchiveProvider(
          fruitRepository: InMemoryFruitRepository());
      await provider.load();

      expect(provider.themeCounts, isEmpty);
      expect(provider.topTheme, isEmpty);
    });

    test('firstPlantedYear tracks the earliest planted year (#99)',
        () async {
      var now = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => now);
      final empty = ArchiveProvider(fruitRepository: repo);
      await empty.load();
      expect(empty.firstPlantedYear, isNull);

      now = DateTime(2025, 5, 5, 12);
      await _harvest(repo,
          seedId: '2025-05-05', text: '작년', at: now);
      now = DateTime(2026, 9, 4, 12);
      await _harvest(repo,
          seedId: '2026-09-04', text: '올해', at: now);
      // 미후기는 제외된다.
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );

      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();
      expect(provider.firstPlantedYear, 2026);

      await repo.updateReview(
        fruitId: 'fruit-2025-05-05',
        memo: '좋았다',
        fidelityScore: 5,
      );
      await provider.load();
      expect(provider.firstPlantedYear, 2025);
    });

    test('plantedInYear filters by harvest year (#97)', () async {
      var now = DateTime(2025, 5, 5, 12);
      final repo = InMemoryFruitRepository(clock: () => now);
      await _harvest(repo,
          seedId: '2025-05-05', text: '작년', at: now);
      await repo.updateReview(
        fruitId: 'fruit-2025-05-05',
        memo: '좋았다',
        fidelityScore: 4,
      );
      now = DateTime(2026, 9, 4, 12);
      await _harvest(repo,
          seedId: '2026-09-04', text: '올해', at: now);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );

      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      expect(provider.plantedInYear(2025).single.text, '작년');
      expect(provider.plantedInYear(2026).single.text, '올해');
      expect(provider.plantedInYear(2024), isEmpty);
    });
  });

  group('FruitRain layout', () {
    test('drops do not overlap on a phone screen (#100)', () {
      final specs = FruitRain.layoutDrops(
        width: 350,
        height: 800,
        random: Random(42),
      );

      expect(specs.length, FruitRain.dropCount);
      for (final spec in specs) {
        expect(spec.size,
            inInclusiveRange(FruitRain.minSize, FruitRain.maxSize));
      }
      // 이웃 중심 간격이 두 방울 반지름 합 + 여유 이상이다.
      for (var i = 0; i < specs.length; i++) {
        for (var j = i + 1; j < specs.length; j++) {
          final distance =
              (specs[i].center - specs[j].center).distance;
          final minGap =
              (specs[i].size + specs[j].size) / 2 + FruitRain.margin;
          expect(distance, greaterThanOrEqualTo(minGap - 0.01));
        }
      }
    });

    test('phases spread drops across the full height (#103)', () {
      final specs = FruitRain.layoutDrops(
        width: 350,
        height: 800,
        random: Random(7),
      );

      final phases = specs.map((s) => s.phase).toList()..sort();
      expect(phases.first, moreOrLessEquals(0.0));
      for (var i = 1; i < phases.length; i++) {
        expect(phases[i] - phases[i - 1],
            moreOrLessEquals(1 / FruitRain.dropCount, epsilon: 0.001));
      }
    });
  });

  group('ArchiveScreen grass grid', () {
    Finder horizontalScroller() => find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        );

    testWidgets('scrollbar sits below the cells without overlap (#91)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final provider = ArchiveProvider(
          fruitRepository: InMemoryFruitRepository());
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      final scroller = tester.widget<SingleChildScrollView>(
        horizontalScroller(),
      );
      expect(scroller.padding,
          const EdgeInsets.only(bottom: 12));
      ArchiveScreen.debugToday = null;
    });

    testWidgets('first entry centers today in scroll mode (#98)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04',
          text: '오늘',
          at: at,
          theme: SeedTheme.growth);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 오늘 칸이 화면(390) 가운데付近에 있다.
      final center = tester.getCenter(
        find.byKey(const ValueKey('grass-2026-09-04')),
      );
      expect(center.dx, moreOrLessEquals(195.0, epsilon: 15.0));
      ArchiveScreen.debugToday = null;
    });

    testWidgets('scroll rests on a column boundary at phone width (#83)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final provider = ArchiveProvider(
          fruitRepository: InMemoryFruitRepository());
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 스크롤 모드 유지 + 정지 오프셋이 열 경계의 배수 → 가장자리 반칸 없음.
      expect(horizontalScroller(), findsOneWidget);
      // #86: 1년 전체로 이동할 수 있게 스크롤바가 항상 보인다.
      final scrollbar =
          tester.widget<Scrollbar>(find.byType(Scrollbar));
      expect(scrollbar.thumbVisibility, isTrue);
      final rowElement = tester.element(
        find
            .descendant(
              of: horizontalScroller(),
              matching: find.byType(Row),
            )
            .first,
      );
      final position = Scrollable.of(rowElement).position;
      final unit = ThemeAssets.grassScrollCell(350) + ThemeAssets.grassGap;
      expect(position.maxScrollExtent % unit,
          moreOrLessEquals(0.0, epsilon: 0.01));
      ArchiveScreen.debugToday = null;
    });

    testWidgets('wide screens fit all weeks without scrolling (#72)',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final provider = ArchiveProvider(
          fruitRepository: InMemoryFruitRepository());
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 전체 맞춤 모드에서는 가로 스크롤 뷰가 없다.
      expect(horizontalScroller(), findsNothing);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('pending reviews show a different guide (#84)',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      // 수확만 되고 후기는 없음 → 심어지지 않음 + 다른 안내.
      await _harvest(repo,
          seedId: '2026-09-04', text: '오늘', at: at);
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('2026 · 0개의 열매'), findsOneWidget);
      expect(find.text('완성된 열매에 후기를 남기면 잔디가 심어져요'),
          findsOneWidget);
      expect(find.text('오늘의 씨앗이 자라는 중이에요'), findsNothing);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('unreviewed harvest stays unplanted until review (#65)',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04', text: '오늘', at: at);
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 후기 전에는 잔디가 심어지지 않는다.
      expect(find.text('2026 · 0개의 열매'), findsOneWidget);
      expect(find.byKey(const ValueKey('grass-2026-09-04')),
          findsNothing);

      // 후기를 남기면 바로 심어진다.
      await provider.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      await tester.pumpAndSettle();

      expect(find.text('2026 · 1개의 열매'), findsOneWidget);
      expect(find.byKey(const ValueKey('grass-2026-09-04')),
          findsOneWidget);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('entering the tab reloads harvested fruits (#62)',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04', text: '오늘', at: at);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      // 사전 load 없이 진입 → 화면이 직접 reload한다.
      final provider = ArchiveProvider(fruitRepository: repo);

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('2026 · 1개의 열매'), findsOneWidget);
      expect(find.byKey(const ValueKey('grass-2026-09-04')),
          findsOneWidget);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('empty grid shows the growing notice (#151)',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final provider = ArchiveProvider(
          fruitRepository: InMemoryFruitRepository());
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('2026 · 0개의 열매'), findsOneWidget);
      expect(find.text('오늘의 씨앗이 자라는 중이에요'), findsOneWidget);
      expect(find.text('완성된 열매에 후기를 남기면 잔디가 심어져요'),
          findsNothing);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('past harvest without today shows the growing notice (#174)',
        (tester) async {
      // 어제 수확(후기 대기)만 있고 오늘은 아직 없음 → 성장 중 안내.
      ArchiveScreen.debugToday = DateTime(2026, 9, 5);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04', text: '어제', at: at);
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('오늘의 씨앗이 자라는 중이에요'), findsOneWidget);
      expect(find.text('완성된 열매에 후기를 남기면 잔디가 심어져요'),
          findsNothing);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('planted past harvest without today shows growing (#174)',
        (tester) async {
      // 어제 수확+후기(잔디 있음)만 있고 오늘은 아직 없음 → 성장 중 안내.
      ArchiveScreen.debugToday = DateTime(2026, 9, 5);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04', text: '어제', at: at);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('오늘의 씨앗이 자라는 중이에요'), findsOneWidget);
      expect(find.text('완성된 열매에 후기를 남기면 잔디가 심어져요'),
          findsNothing);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('reviewed fruits show color stats below the grid (#88)',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04',
          text: '성장 열매',
          at: at,
          theme: SeedTheme.growth);
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 후기 전에는 통계가 없다.
      expect(find.text('모은 색깔'), findsNothing);

      await provider.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      await tester.pumpAndSettle();

      expect(find.text('모은 색깔'), findsOneWidget);
      expect(find.text('성장 1개'), findsOneWidget);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('no rain without planted fruits (#89)', (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final provider = ArchiveProvider(
          fruitRepository: InMemoryFruitRepository());
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.byType(FruitRain), findsNothing);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('rain fills the whole screen (#107)', (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04',
          text: '성장 열매',
          at: at,
          theme: SeedTheme.growth);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 비 영역이 본문 높이가 아니라 화면 전체여야 한다.
      expect(tester.getSize(find.byType(FruitRain)),
          const Size(800, 600));
      ArchiveScreen.debugToday = null;
    });

    testWidgets('rain respects the fruit rain setting (#108)',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04',
          text: '성장 열매',
          at: at,
          theme: SeedTheme.growth);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();
      final settings = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
      );
      await settings.load();
      await settings.setFruitRainEnabled(false);

      await tester.pumpWidget(
          _wrap(provider, settings: settings));
      await tester.pumpAndSettle();

      // 설정에서 끄면 비가 오지 않는다.
      expect(find.byType(FruitRain), findsNothing);

      // 다시 켜면 비가 온다.
      await settings.setFruitRainEnabled(true);
      await tester.pumpAndSettle();

      expect(find.byType(FruitRain), findsOneWidget);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('garden today follows the shared clock (#115)',
        (tester) async {
      ArchiveScreen.debugToday = null;
      final provider = ArchiveProvider(
          fruitRepository: InMemoryFruitRepository());
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      final thisYear = DateTime.now().year;
      expect(find.text('$thisYear · 0개의 열매'), findsOneWidget);

      // 공용 시계를 내년으로 미루면 정원의 연도 기준도 따라간다.
      final now = DateTime.now();
      DebugClock.shift(
          DateTime(now.year + 1, 1, 5).difference(now));
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('${thisYear + 1} · 0개의 열매'), findsOneWidget);
    });

    testWidgets('rain shows the top theme fruit behind the grid (#89)',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04',
          text: '성장 열매',
          at: at,
          theme: SeedTheme.growth);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.byType(FruitRain), findsOneWidget);
      // 배경 레이어 + 본문 구조.
      expect(find.byType(Stack), findsWidgets);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('rain drops move diagonally over time (#89)',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04',
          text: '성장 열매',
          at: at,
          theme: SeedTheme.growth);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      // 티커를 살려 둔다 (무한 애니메이션이라 pumpAndSettle 금지).
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(
              create: (_) => SettingsProvider(
                settingsRepository: InMemorySettingsRepository(),
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => SeedProvider(
                seedRepository: InMemorySeedRepository(),
                quoteRepository: InMemoryQuoteRepository(),
                fruitRepository: InMemoryFruitRepository(),
              ),
            ),
          ],
          child: const MaterialApp(home: ArchiveScreen()),
        ),
      );
      await tester.pump();

      final before =
          tester.getTopLeft(find.byKey(const ValueKey('rain-drop-0')));
      await tester.pump(const Duration(seconds: 3));
      final after =
          tester.getTopLeft(find.byKey(const ValueKey('rain-drop-0')));

      expect(after, isNot(before));
      ArchiveScreen.debugToday = null;
    });

    testWidgets('drops stay within bounds across the full cycle (#94)',
        (tester) async {
      const width = 300.0;
      const height = 600.0;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: height,
              child: FruitRain(imagePath: 'x', opacity: 1),
            ),
          ),
        ),
      );
      await tester.pump();

      final tops = <double>[];
      var inBounds = true;
      // 14초 한 주기를 0.5초씩 전진하며 전 방울 위치를 확인한다.
      // 테스트에서는 이미지가 로드 실패해 0으로 그려지지만,
      // 배치는 모델 크기(최대 64) 기준이므로 그 밴드로 검증한다.
      for (var i = 0; i <= 28; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        for (var d = 0; d < FruitRain.dropCount; d++) {
          final pos = tester
              .getTopLeft(find.byKey(ValueKey('rain-drop-$d')));
          if (pos.dx < -65.0 || pos.dx > width + 1) {
            inBounds = false;
          }
          tops.add(pos.dy);
        }
      }

      // 가로 범위를 벗어나지 않고, 세로는 화면 전체를 오간다.
      expect(inBounds, isTrue);
      expect(tops.reduce(min) < 0, isTrue);
      expect(tops.reduce(max) > height, isTrue);
    });

    testWidgets('year navigation shows past plantings (#99)',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      var now = DateTime(2025, 5, 5, 12);
      final repo = InMemoryFruitRepository(clock: () => now);
      await _harvest(repo,
          seedId: '2025-05-05', text: '작년 열매', at: now);
      await repo.updateReview(
        fruitId: 'fruit-2025-05-05',
        memo: '좋았다',
        fidelityScore: 5,
      );
      now = DateTime(2026, 9, 4, 12);
      await _harvest(repo,
          seedId: '2026-09-04', text: '올해 열매', at: now);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 당해 연도부터 보인다.
      expect(find.text('2026 · 1개의 열매'), findsOneWidget);
      expect(find.byKey(const ValueKey('grass-2026-09-04')),
          findsOneWidget);

      // 작년으로 이동한다.
      await tester.tap(find.byKey(const ValueKey('year-prev')));
      await tester.pumpAndSettle();

      expect(find.text('2025 · 1개의 열매'), findsOneWidget);
      expect(find.byKey(const ValueKey('grass-2025-05-05')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('grass-2026-09-04')),
          findsNothing);

      // 처음 심어진 년도에서는 뒤로 더 못 간다.
      final prev = tester.widget<IconButton>(
        find.byKey(const ValueKey('year-prev')),
      );
      expect(prev.onPressed, isNull);

      // 올해로 복귀한다.
      await tester.tap(find.byKey(const ValueKey('year-next')));
      await tester.pumpAndSettle();

      expect(find.text('2026 · 1개의 열매'), findsOneWidget);
      final next = tester.widget<IconButton>(
        find.byKey(const ValueKey('year-next')),
      );
      expect(next.onPressed, isNull);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('today button returns from a past year (#126)',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      var now = DateTime(2025, 5, 5, 12);
      final repo = InMemoryFruitRepository(clock: () => now);
      await _harvest(repo,
          seedId: '2025-05-05', text: '작년 열매', at: now);
      await repo.updateReview(
        fruitId: 'fruit-2025-05-05',
        memo: '좋았다',
        fidelityScore: 5,
      );
      now = DateTime(2026, 9, 4, 12);
      await _harvest(repo,
          seedId: '2026-09-04', text: '올해 열매', at: now);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      IconButton todayButton() => tester.widget<IconButton>(
            find.byKey(const ValueKey('today-button')),
          );

      // 올해 보기에서도 버튼이 켜져 있다.
      expect(todayButton().onPressed, isNotNull);

      // 작년으로 이동하면 올해 복귀 + 버튼 유지.
      await tester.tap(find.byKey(const ValueKey('year-prev')));
      await tester.pumpAndSettle();

      expect(find.text('2025 · 1개의 열매'), findsOneWidget);
      expect(todayButton().onPressed, isNotNull);

      // 오늘 버튼을 누르면 올해 보기로 돌아온다.
      await tester.tap(find.byKey(const ValueKey('today-button')));
      await tester.pumpAndSettle();

      expect(find.text('2026 · 1개의 열매'), findsOneWidget);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('today button recenters scrolled grid (#126)',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04', text: '올해 열매', at: at);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      double gridPixels() => tester
          .state<ScrollableState>(find.byWidgetPredicate(
              (w) => w is Scrollable && w.axis == Axis.horizontal))
          .position
          .pixels;
      final centered = gridPixels();

      // 옆으로 스크롤해서 오늘에서 멀어진다.
      await tester.drag(
          find.byWidgetPredicate(
              (w) => w is Scrollable && w.axis == Axis.horizontal),
          const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(gridPixels(), isNot(centered));

      // 올해 보기에서도 오늘 버튼을 누르면 중앙으로 돌아온다.
      await tester.tap(find.byKey(const ValueKey('today-button')));
      await tester.pumpAndSettle();

      expect(find.text('2026 · 1개의 열매'), findsOneWidget);
      expect(gridPixels(), centered);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('today cell has a dedicated outline (#125)',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final provider = ArchiveProvider(
          fruitRepository: InMemoryFruitRepository());
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 오늘 빈칸에 전용 테두리가 정확히 1개 있다 (테마·금색과 무관).
      bool borderIs(Color color, Widget w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border is Border &&
          ((w.decoration as BoxDecoration).border as Border).top.color ==
              color;
      final expected =
          ThemeAssets.todayOutline(Brightness.light);
      expect(find.byWidgetPredicate((w) => borderIs(expected, w)),
          findsOneWidget);
      expect(find.byWidgetPredicate((w) => borderIs(AppTheme.gold, w)),
          findsNothing);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('today outline ignores the seed theme (#125)',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final seedProvider = SeedProvider(
        seedRepository: InMemorySeedRepository(
          themePicker: () => SeedTheme.vitality,
        ),
        quoteRepository: InMemoryQuoteRepository(),
        fruitRepository: InMemoryFruitRepository(),
      );
      await seedProvider.ensureTodaySeed();
      final provider = ArchiveProvider(
          fruitRepository: InMemoryFruitRepository());
      await provider.load();

      await tester.pumpWidget(_wrap(provider, seed: seedProvider));
      await tester.pumpAndSettle();

      // 씨앗 테마와 무관하게 전용색이다.
      final expected =
          ThemeAssets.todayOutline(Brightness.light);
      bool borderIs(Color color, Widget w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border is Border &&
          ((w.decoration as BoxDecoration).border as Border).top.color ==
              color;
      expect(find.byWidgetPredicate((w) => borderIs(expected, w)),
          findsOneWidget);
      expect(
          find.byWidgetPredicate((w) => borderIs(
              ThemeAssets.cellColor(
                  SeedTheme.vitality, Brightness.light),
              w)),
          findsNothing);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('review sheet shows the quote source (#123)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FruitReviewSheet(
              quoteText: 't',
              author: 'a',
              dateLabel: '2026.09.04',
              imagePath: '',
              initialMemo: '',
              initialScore: 0,
              readOnly: true,
              source: '한국어 위키인용집 (CC BY-SA 4.0)',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('출처'));
      await tester.pumpAndSettle();

      expect(find.text('명언 출처'), findsOneWidget);
      expect(find.text('한국어 위키인용집 (CC BY-SA 4.0)'),
          findsOneWidget);
    });

    testWidgets('review sheet hides the source button without source',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FruitReviewSheet(
              quoteText: 't',
              author: 'a',
              dateLabel: '2026.09.04',
              imagePath: '',
              initialMemo: '',
              initialScore: 0,
              readOnly: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('출처'), findsNothing);
    });

    testWidgets('review sheet shows the explanation when present (#216)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FruitReviewSheet(
              quoteText: '아는 것이 힘이다.',
              author: '프랜시스 베이컨',
              dateLabel: '2026.09.04',
              imagePath: '',
              initialMemo: '',
              initialScore: 0,
              readOnly: true,
              explanation: '배우는 게 자신을 강하게 만들어요.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // #177: 해설도 단어 중간 줄바꿈 방지 처리가 되어 있다.
      expect(find.text(keepWordsTogether('배우는 게 자신을 강하게 만들어요.')),
          findsOneWidget);
    });

    testWidgets('review sheet hides the explanation when empty (#216)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FruitReviewSheet(
              quoteText: 't',
              author: 'a',
              dateLabel: '2026.09.04',
              imagePath: '',
              initialMemo: '',
              initialScore: 0,
              readOnly: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 해설 위젯 자체가 없다 (출처 버튼·후기 카드와 혼동 없음).
      expect(find.text('출처'), findsNothing);
      expect(find.byType(FruitReviewSheet), findsOneWidget);
    });

    testWidgets('write-mode sheet shows review hints (#223)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FruitReviewSheet(
              quoteText: 't',
              author: 'a',
              dateLabel: '2026.09.04',
              imagePath: '',
              initialMemo: '',
              initialScore: 0,
              onSave: ({required memo, required fidelityScore}) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 별점 도움말이 흐리게 보인다.
      expect(find.text('오늘 말씨를 얼마나 품고 살았나요?'),
          findsOneWidget);
      final helper = tester
          .widget<Text>(find.text('오늘 말씨를 얼마나 품고 살았나요?'));
      expect(helper.textAlign, TextAlign.center);
      expect(helper.style!.fontSize, 12);
      // 한줄평 힌트가 새 문구다.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.hintText, '말씨와 함께 오늘을 돌아보세요.');
    });

    testWidgets('read-only sheet hides review hints (#223)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FruitReviewSheet(
              quoteText: 't',
              author: 'a',
              dateLabel: '2026.09.04',
              imagePath: '',
              initialMemo: '',
              initialScore: 0,
              readOnly: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 보관 상세(읽기 전용)에는 도움말이 없다.
      expect(
          find.text('오늘 말씨를 얼마나 품고 살았나요?'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('read-only memo is a distinct left-aligned card (#150)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FruitReviewSheet(
              quoteText: '명언本文',
              author: '작자',
              dateLabel: '2026.09.04',
              imagePath: '',
              initialMemo: '내 후기',
              initialScore: 4,
              readOnly: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 명언은 가운데 정렬, 내 후기는 왼쪽 정렬 카드로 구분된다.
      final quote = tester.widget<Text>(find.text('"${keepWordsTogether('명언本文')}"'));
      expect(quote.textAlign, TextAlign.center);
      final memo = tester.widget<Text>(find.text('내 후기'));
      expect(memo.textAlign, TextAlign.left);
      expect(memo.style!.fontSize, 14);
      // 카드 배경이 있다 (명언 영역과 시각적 분리).
      expect(
        find.ancestor(
          of: find.text('내 후기'),
          matching: find.byWidgetPredicate((w) =>
              w is Container && w.decoration is BoxDecoration),
        ),
        findsOneWidget,
      );
    });

    testWidgets('dot images use nearest-neighbor filtering (#160)',
        (tester) async {
      // 후기 카드 열매 이미지 (실에셋 로드).
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FruitReviewSheet(
              quoteText: 't',
              author: 'a',
              dateLabel: '2026.09.04',
              imagePath: 'assets/images/grape.png',
              initialMemo: 'm',
              initialScore: 4,
              readOnly: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<Image>(find.byType(Image)).filterQuality,
        FilterQuality.none,
      );
      // #160: 150px 소스의 정수배(0.5x = 75)로 표시한다.
      expect(tester.widget<Image>(find.byType(Image)).width, 75);

      // 열매 비 방울 (실에셋 로드).
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 600,
              child: FruitRain(
                  imagePath: 'assets/images/grape.png', opacity: 1),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsWidgets);
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        expect(image.filterQuality, FilterQuality.none);
      }
    });

    testWidgets('harvested dates show themed cells', (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04',
          text: '성장 열매',
          at: at,
          theme: SeedTheme.growth);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('2026 · 1개의 열매'), findsOneWidget);
      expect(find.byKey(const ValueKey('grass-2026-09-04')),
          findsOneWidget);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('tapping a cell opens the read-only detail card',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04',
          text: '성장 열매',
          at: at,
          theme: SeedTheme.growth);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('grass-2026-09-04')));
      await tester.pumpAndSettle();

      expect(find.textContaining(keepWordsTogether('성장 열매')), findsOneWidget);
      expect(find.text('오늘의 점수'), findsOneWidget);
      expect(find.text('오늘의 후기'), findsOneWidget);
      // #48: 보관에서는 저장 UI가 없다.
      expect(find.text('후기 저장하기'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('detail card exposes the quote source button (#123)',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04',
          text: '성장 열매',
          at: at,
          theme: SeedTheme.growth,
          source: '한국어 위키인용집 (CC BY-SA 4.0)');
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('grass-2026-09-04')));
      await tester.pumpAndSettle();

      // 날짜별 명언 조회에서 출처가 전달된다.
      // (다이얼로그 동작은 후기 카드 단독 테스트에서 검증.)
      expect(find.text('출처'), findsOneWidget);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('detail card shows the saved review read-only',
        (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04', text: '성장 열매', at: at);
      await repo.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '오늘 충실히 살았다',
        fidelityScore: 4,
      );
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('grass-2026-09-04')));
      await tester.pumpAndSettle();

      // 저장된 별점·후기만 표시된다.
      expect(find.text('오늘 충실히 살았다'), findsOneWidget);
      expect(find.text('후기 저장하기'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('read-only sheet shows an empty state without a review',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FruitReviewSheet(
              quoteText: '성장 열매',
              author: '작자',
              dateLabel: '2026.09.04',
              imagePath: '',
              initialMemo: '',
              initialScore: 0,
              readOnly: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('작성된 후기가 없어요'), findsOneWidget);
      expect(find.text('후기 저장하기'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('plant motion (#195)', () {
    // 티커를 끄지 않은 래퍼 (1회성 팝은 settle된다).
    // 열매 비는 설정으로 꺼서 무한 낙하를 피한다.
    Widget wrapTickerOn(
      ArchiveProvider provider, {
      required SettingsProvider settings,
      required SeedProvider seed,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: seed),
        ],
        child: const MaterialApp(home: ArchiveScreen()),
      );
    }

    Future<(ArchiveProvider, SettingsProvider, SeedProvider)> setupReviewed({
      required DateTime at,
      required DateTime today,
    }) async {
      ArchiveScreen.debugToday = today;
      // 수확 시각을 고정해야 수확일 칸에 심긴다 (기본 시계는 실제 현재 시각).
      final fruitRepo = InMemoryFruitRepository(clock: () => at);
      await _harvest(fruitRepo,
          seedId: 's', text: 't', at: at, theme: SeedTheme.vitality);
      await fruitRepo.updateReview(
        fruitId: 'fruit-s',
        memo: '충실했다',
        fidelityScore: 5,
      );
      final provider = ArchiveProvider(fruitRepository: fruitRepo);
      await provider.load();
      final settingsRepo = InMemorySettingsRepository();
      await settingsRepo.setFruitRainEnabled(false);
      final settings =
          SettingsProvider(settingsRepository: settingsRepo);
      await settings.load();
      final seed = SeedProvider(
        seedRepository: InMemorySeedRepository(),
        quoteRepository: InMemoryQuoteRepository(),
        fruitRepository: InMemoryFruitRepository(),
      );
      return (provider, settings, seed);
    }

    ScaleTransition popOf(WidgetTester tester) =>
        tester.widget<ScaleTransition>(find.descendant(
          of: find.byType(PlantCell),
          matching: find.byType(ScaleTransition),
        ));

    testWidgets('newly planted cell pops once', (tester) async {
      final at = DateTime(2026, 9, 4, 12);
      final (provider, settings, seed) =
          await setupReviewed(at: at, today: DateTime(2026, 9, 4));

      await tester.pumpWidget(wrapTickerOn(provider,
          settings: settings, seed: seed));
      await tester.pump();
      expect(find.byType(PlantCell), findsOneWidget);
      // 전환 중에는 1.0이 아니다.
      expect(popOf(tester).scale.value, isNot(1.0));

      await tester.pumpAndSettle();
      expect(popOf(tester).scale.value, 1.0);

      // 다시 그려도 재생하지 않는다.
      await tester.pumpWidget(wrapTickerOn(provider,
          settings: settings, seed: seed));
      await tester.pump();
      expect(popOf(tester).scale.value, 1.0);
    });

    testWidgets('old cells stay still', (tester) async {
      final (provider, settings, seed) = await setupReviewed(
          at: DateTime(2026, 6, 1, 12), today: DateTime(2026, 9, 4));

      await tester.pumpWidget(wrapTickerOn(provider,
          settings: settings, seed: seed));
      await tester.pump();

      // 묵은 칸은 첫 프레임부터 정적이다.
      expect(find.byType(PlantCell), findsOneWidget);
      expect(popOf(tester).scale.value, 1.0);
    });
  });
}

/// `Fruit.fromMap`의 `harvestedAt.toDate()` 호출용 가짜 Timestamp.
class _FakeTimestamp {
  DateTime toDate() => DateTime(2026, 9, 4, 12);
}
