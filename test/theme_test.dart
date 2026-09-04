import 'package:flutter_test/flutter_test.dart';

import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/domain/seed.dart';

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
}
