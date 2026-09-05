import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/archive/presentation/archive_screen.dart';
import 'package:malssi/features/archive/presentation/fruit_review_sheet.dart';
import 'package:malssi/features/archive/providers/archive_providers.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/domain/seed.dart';

Widget _wrap(ArchiveProvider provider) {
  return MultiProvider(
    providers: [ChangeNotifierProvider.value(value: provider)],
    child: const MaterialApp(home: ArchiveScreen()),
  );
}

Future<void> _harvest(
  InMemoryFruitRepository repo, {
  required String seedId,
  required String text,
  required DateTime at,
  String theme = '',
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
    ),
  );
}

void main() {
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
  });

  group('ArchiveScreen grass grid', () {
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
      expect(find.text('최근 1년 · 0개의 열매'), findsOneWidget);
      expect(find.byKey(const ValueKey('grass-2026-09-04')),
          findsNothing);

      // 후기를 남기면 바로 심어진다.
      await provider.updateReview(
        fruitId: 'fruit-2026-09-04',
        memo: '좋았다',
        fidelityScore: 4,
      );
      await tester.pumpAndSettle();

      expect(find.text('최근 1년 · 1개의 열매'), findsOneWidget);
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

      expect(find.text('최근 1년 · 1개의 열매'), findsOneWidget);
      expect(find.byKey(const ValueKey('grass-2026-09-04')),
          findsOneWidget);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('empty grid guides to the seed tab', (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final provider = ArchiveProvider(
          fruitRepository: InMemoryFruitRepository());
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('정원'), findsOneWidget);
      expect(find.text('최근 1년 · 0개의 열매'), findsOneWidget);
      expect(find.text('말씨 탭에서 씨앗을 키우고 후기를 남기면 잔디가 심어져요'),
          findsOneWidget);
      // #75: 정원 탭 바는 흙색 (테스트 기본 밝기=라이트).
      final nav =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect((nav.decoration as BoxDecoration).color,
          AppTheme.navGardenLight);
      ArchiveScreen.debugToday = null;
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

      expect(find.text('최근 1년 · 1개의 열매'), findsOneWidget);
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

      expect(find.textContaining('성장 열매'), findsOneWidget);
      expect(find.text('오늘의 점수'), findsOneWidget);
      expect(find.text('오늘의 후기'), findsOneWidget);
      // #48: 보관에서는 저장 UI가 없다.
      expect(find.text('후기 저장하기'), findsNothing);
      expect(find.byType(TextField), findsNothing);
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
}

/// `Fruit.fromMap`의 `harvestedAt.toDate()` 호출용 가짜 Timestamp.
class _FakeTimestamp {
  DateTime toDate() => DateTime(2026, 9, 4, 12);
}
