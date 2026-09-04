import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/archive/presentation/archive_screen.dart';
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
  });

  group('ArchiveScreen grass grid', () {
    testWidgets('empty grid guides to the seed tab', (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final provider = ArchiveProvider(
          fruitRepository: InMemoryFruitRepository());
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('보관'), findsWidgets);
      expect(find.text('최근 1년 · 0개의 열매'), findsOneWidget);
      expect(find.text('씨앗 탭에서 오늘의 씨앗을 깨면 잔디가 채워져요'),
          findsOneWidget);
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
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('최근 1년 · 1개의 열매'), findsOneWidget);
      expect(find.byKey(const ValueKey('grass-2026-09-04')),
          findsOneWidget);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('tapping a cell opens the detail card', (tester) async {
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
      await tester
          .tap(find.byKey(const ValueKey('grass-2026-09-04')));
      await tester.pumpAndSettle();

      expect(find.textContaining('성장 열매'), findsOneWidget);
      expect(find.text('오늘의 점수'), findsOneWidget);
      expect(find.text('오늘의 후기'), findsOneWidget);
      ArchiveScreen.debugToday = null;
    });

    testWidgets('saving a review updates the fruit', (tester) async {
      ArchiveScreen.debugToday = DateTime(2026, 9, 4);
      final at = DateTime(2026, 9, 4, 12);
      final repo = InMemoryFruitRepository(clock: () => at);
      await _harvest(repo,
          seedId: '2026-09-04', text: '성장 열매', at: at);
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('grass-2026-09-04')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField), '오늘 충실히 살았다');
      await tester.tap(find.byKey(const ValueKey('score-4')));
      await tester.pump();
      await tester.tap(find.text('후기 저장하기'));
      await tester.pumpAndSettle();

      expect(provider.fruits.single.memo, '오늘 충실히 살았다');
      expect(provider.fruits.single.fidelityScore, 4);
      // 시트가 닫혔다.
      expect(find.text('후기 저장하기'), findsNothing);
      ArchiveScreen.debugToday = null;
    });
  });
}

/// `Fruit.fromMap`의 `harvestedAt.toDate()` 호출용 가짜 Timestamp.
class _FakeTimestamp {
  DateTime toDate() => DateTime(2026, 9, 4, 12);
}
