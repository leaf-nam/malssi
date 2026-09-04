import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/data/seed_repository.dart';
import 'package:malssi/features/seed/domain/seed.dart';
import 'package:malssi/features/seed/presentation/seed_screen.dart';
import 'package:malssi/features/seed/providers/seed_providers.dart';

SeedProvider _buildProvider({DateTime Function()? clock}) {
  final seedRepository = InMemorySeedRepository(clock: clock);
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
      );
      final restored = Seed.fromMap(
          seed.toMap()..['createdAt'] = _FakeTimestamp(seed.createdAt));

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
    test('ensure then open reveals a quote and harvests a fruit', () async {
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

      await provider.openSeed();
      expect(provider.todaySeed!.isOpened, isTrue);
      expect(provider.revealedQuote, isNotNull);
      expect(provider.errorMessage, isNull);

      final fruits = await fruitRepository.getFruits();
      expect(fruits.length, 1);
      expect(fruits.first.text, provider.revealedQuote!.text);
    });
  });

  group('SeedScreen', () {
    testWidgets('locked seed shows the open button', (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('오늘의 씨앗'), findsOneWidget);
      expect(find.text('씨앗 깨기'), findsOneWidget);
    });

    testWidgets('tapping open reveals the quote', (tester) async {
      final provider = _buildProvider();
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.text('씨앗 깨기'));
      await tester.pumpAndSettle();

      expect(find.text('씨앗 깨기'), findsNothing);
      expect(provider.revealedQuote, isNotNull);
      expect(find.textContaining(provider.revealedQuote!.text),
          findsOneWidget);
    });
  });
}
