import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/data/seed_repository.dart';
import 'package:malssi/features/seed/domain/seed.dart';
import 'package:malssi/features/seed/presentation/seed_screen.dart';
import 'package:malssi/features/seed/providers/seed_providers.dart';

SeedProvider _buildProvider(
    {DateTime Function()? clock, String Function()? themePicker}) {
  final seedRepository =
      InMemorySeedRepository(clock: clock, themePicker: themePicker);
  return SeedProvider(
    seedRepository: seedRepository,
    quoteRepository: InMemoryQuoteRepository(),
    fruitRepository: InMemoryFruitRepository(clock: clock),
  );
}

Widget _wrap(SeedProvider provider) {
  return MultiProvider(
    providers: [ChangeNotifierProvider.value(value: provider)],
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

      expect(find.text('말씨'), findsOneWidget);
      expect(find.text('씨앗 심기'), findsOneWidget);
      // #59: 말씨 탭 배경은 니어블랙 고정.
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppTheme.abyss);
      // #75: 말씨 탭 바도 배경과 동일한 검은색.
      final nav =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(nav.backgroundColor, AppTheme.abyss);
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
      expect(find.textContaining(provider.revealedQuote!.text),
          findsOneWidget);
      // #57: 성장 형태(에셋)만 보이고 단계·안내 문구는 없다.
      expect(find.textContaining('단계 성장 중'), findsNothing);
      expect(find.textContaining('2시간마다'), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      // #51: 명언 영역(2/3) : 성장 에셋(1/3).
      final growingFlexes = tester
          .widgetList<Expanded>(find.byType(Expanded))
          .map((e) => e.flex)
          .toList();
      expect(growingFlexes[0], 2);
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
      expect(find.textContaining(provider.revealedQuote!.text),
          findsOneWidget);
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
