import 'package:flutter_test/flutter_test.dart';

import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/core/theme/theme_assets.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/data/seed_repository.dart';
import 'package:malssi/features/seed/domain/seed.dart';
import 'package:malssi/features/seed/providers/seed_providers.dart';

/// Firestore `Timestamp` 흉내 (`fromMap`의 `.toDate()` 호출용).
class _FakeTimestamp {
  _FakeTimestamp(this._date);
  final DateTime _date;
  DateTime toDate() => _date;
}

void main() {
  group('SeedTheme', () {
    test('has 7 unique keys', () {
      expect(SeedTheme.values.length, 7);
      expect(SeedTheme.values.toSet().length, 7);
    });

    test('isValid accepts only the 7 keys', () {
      for (final key in SeedTheme.values) {
        expect(SeedTheme.isValid(key), isTrue);
      }
      expect(SeedTheme.isValid(''), isFalse);
      expect(SeedTheme.isValid('apple'), isFalse);
    });
  });

  group('theme field serialization', () {
    test('Quote keeps theme through fromMap/toMap', () {
      final quote = Quote(
        id: 'q1',
        text: 't',
        author: 'a',
        likes: 0,
        createdAt: DateTime(2026, 9, 4),
        theme: SeedTheme.growth,
      );
      final restored = Quote.fromMap(
          quote.toMap()..['createdAt'] = _FakeTimestamp(quote.createdAt));

      expect(restored.theme, SeedTheme.growth);
      expect(restored.copyWith(theme: SeedTheme.peace).theme,
          SeedTheme.peace);
    });

    test('Quote defaults missing theme to empty', () {
      final quote = Quote.fromMap({
        'id': 'q1',
        'createdAt': _FakeTimestamp(DateTime(2026, 9, 4)),
      });

      expect(quote.theme, isEmpty);
    });

    test('Seed keeps theme through fromMap/toMap', () {
      final seed = Seed(
        id: '2026-09-04',
        dateKey: '2026-09-04',
        quoteId: '',
        status: SeedStatus.locked,
        createdAt: DateTime(2026, 9, 4),
        theme: SeedTheme.vitality,
      );
      final restored = Seed.fromMap(
          seed.toMap()..['createdAt'] = _FakeTimestamp(seed.createdAt));

      expect(restored.theme, SeedTheme.vitality);
    });

    test('Fruit keeps theme through fromMap/toMap', () {
      final fruit = Fruit(
        id: 'fruit-2026-09-04',
        seedId: '2026-09-04',
        quoteId: 'q1',
        text: 't',
        author: 'a',
        harvestedAt: DateTime(2026, 9, 4, 12),
        theme: SeedTheme.wisdom,
      );
      final restored = Fruit.fromMap(
          fruit.toMap()..['harvestedAt'] = _FakeTimestamp(fruit.harvestedAt));

      expect(restored.theme, SeedTheme.wisdom);
    });

    test('harvestFromSeed snapshots the quote theme', () async {
      final repo = InMemoryFruitRepository();
      final seed = Seed(
        id: '2026-09-04',
        dateKey: '2026-09-04',
        quoteId: 'q1',
        status: SeedStatus.opened,
        createdAt: DateTime(2026, 9, 4),
        theme: SeedTheme.health,
      );
      final quote = Quote(
        id: 'q1',
        text: 't',
        author: 'a',
        likes: 0,
        createdAt: DateTime(2026, 9, 4),
        theme: SeedTheme.health,
      );

      final fruit = await repo.harvestFromSeed(seed: seed, quote: quote);

      expect(fruit.theme, SeedTheme.health);
    });
  });

  group('ThemeAssets', () {
    test('maps all 7 themes to asset paths', () {
      expect(ThemeAssets.fruitImage(SeedTheme.vitality),
          'assets/images/strawberry.png');
      expect(ThemeAssets.fruitImage(SeedTheme.happiness),
          'assets/images/orange.png');
      expect(ThemeAssets.fruitImage(SeedTheme.growth),
          'assets/images/lemon.png');
      expect(ThemeAssets.fruitImage(SeedTheme.health),
          'assets/images/kiwi.png');
      expect(ThemeAssets.fruitImage(SeedTheme.peace),
          'assets/images/blueberry.png');
      expect(ThemeAssets.fruitImage(SeedTheme.relationship),
          'assets/images/grape.png');
      expect(ThemeAssets.fruitImage(SeedTheme.wisdom),
          'assets/images/grapefruit.png');
      expect(ThemeAssets.seedImage(SeedTheme.growth),
          'assets/images/lemon_seed.png');
      expect(ThemeAssets.labelOf(SeedTheme.growth), '성장');
    });

    test('unknown theme falls back', () {
      expect(ThemeAssets.fruitImage(''), isEmpty);
      expect(ThemeAssets.seedImage('nope'), isEmpty);
      expect(ThemeAssets.labelOf(''), '오늘의 씨앗');
    });

    test('cellColor covers all 7 themes plus fallback', () {
      for (final key in SeedTheme.values) {
        expect(ThemeAssets.cellColor(key), isNotNull);
      }
      expect(ThemeAssets.cellColor(''), isNotNull);
    });
  });

  group('theme selection (random)', () {
    test('getTodaySeed assigns the picker theme', () async {
      final repo = InMemorySeedRepository(
        clock: () => DateTime(2026, 9, 4, 12),
        themePicker: () => SeedTheme.growth,
      );

      final seed = await repo.getTodaySeed();

      expect(seed.theme, SeedTheme.growth);
    });

    test('default picker assigns a valid theme', () async {
      final repo = InMemorySeedRepository(
        clock: () => DateTime(2026, 9, 4, 12),
      );

      final seed = await repo.getTodaySeed();

      expect(SeedTheme.isValid(seed.theme), isTrue);
    });

    test('getRandomQuoteByTheme returns a matching quote', () async {
      final repo = InMemoryQuoteRepository();

      final quote = await repo.getRandomQuoteByTheme(SeedTheme.growth);

      expect(quote.theme, SeedTheme.growth);
    });

    test('getRandomQuoteByTheme falls back when the theme is missing',
        () async {
      final repo = InMemoryQuoteRepository();

      // 시드 데이터에 없는 테마 → 전체 랜덤 폴백.
      final quote =
          await repo.getRandomQuoteByTheme(SeedTheme.happiness);

      expect(quote.id, isNotEmpty);
    });

    test('openSeed reveals a quote of the seed theme', () async {
      final seedRepository = InMemorySeedRepository(
        clock: () => DateTime(2026, 9, 4, 12),
        themePicker: () => SeedTheme.growth,
      );
      final fruitRepository = InMemoryFruitRepository(
        clock: () => DateTime(2026, 9, 4, 12),
      );
      final provider = SeedProvider(
        seedRepository: seedRepository,
        quoteRepository: InMemoryQuoteRepository(),
        fruitRepository: fruitRepository,
      );

      await provider.ensureTodaySeed();
      await provider.openSeed();

      expect(provider.revealedQuote!.theme, SeedTheme.growth);
      final fruits = await fruitRepository.getFruits();
      expect(fruits.single.theme, SeedTheme.growth);
    });
  });
}
