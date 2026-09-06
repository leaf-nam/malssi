import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/core/services/local_store.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/data/seed_repository.dart';
import 'package:malssi/features/seed/domain/seed.dart';
import 'package:malssi/features/settings/data/settings_repository.dart';

Quote _quote({String theme = ''}) => Quote(
      id: 'q',
      text: 't',
      author: 'a',
      likes: 0,
      createdAt: DateTime(2026, 1, 1),
      theme: theme,
    );

void main() {
  group('PrefsLocalStore', () {
    test('round-trips lists and maps with empty defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await PrefsLocalStore.create();

      expect(await store.readList('missing'), isEmpty);
      expect(await store.readMap('missing'), isEmpty);

      await store.writeList('k', [
        {'a': 1, 'b': 'x'}
      ]);
      await store.writeMap('m', {'c': true});

      expect(await store.readList('k'), [
        {'a': 1, 'b': 'x'}
      ]);
      expect(await store.readMap('m'), {'c': true});
    });
  });

  group('date codec', () {
    test('encodeDates/decodeDates round-trips model timestamps', () {
      final encoded = encodeDates(
        {'id': 'x', 'createdAt': DateTime(2026, 9, 4, 12)},
        {'createdAt'},
      );

      expect(encoded['createdAt'], '2026-09-04T12:00:00.000');

      final decoded = decodeDates(encoded, {'createdAt'});
      expect(
        (decoded['createdAt'] as dynamic).toDate(),
        DateTime(2026, 9, 4, 12),
      );
    });
  });

  group('seed persistence (#122)', () {
    test('planted seed survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await PrefsLocalStore.create();
      final first = InMemorySeedRepository(
        clock: () => DateTime(2026, 9, 4, 12),
        themePicker: () => SeedTheme.growth,
        store: store,
      );
      await first.load();
      final seed = await first.getTodaySeed();
      await first.plantSeed(seedId: seed.id, quote: _quote());

      // 재시작: 새 인스턴스가 저장분을 복원한다.
      final second = InMemorySeedRepository(
        clock: () => DateTime(2026, 9, 4, 13),
        store: store,
      );
      await second.load();

      final active = await second.getActiveSeed();
      expect(active.id, '2026-09-04');
      expect(active.isGrowing, isTrue);
      expect(active.quoteId, 'q');
    });

    test('load with an empty store starts fresh', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await PrefsLocalStore.create();
      final repo = InMemorySeedRepository(store: store);
      await repo.load();

      final seed = await repo.getTodaySeed();
      expect(seed.isLocked, isTrue);
    });
  });

  group('fruit persistence (#122)', () {
    test('reviewed fruit survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await PrefsLocalStore.create();
      final at = DateTime(2026, 9, 4, 12);
      final first = InMemoryFruitRepository(
          clock: () => at, store: store);
      final seed = Seed(
        id: '2026-09-04',
        dateKey: '2026-09-04',
        quoteId: 'q',
        status: SeedStatus.complete,
        createdAt: at,
        theme: SeedTheme.growth,
        plantedAt: at,
      );
      final fruit =
          await first.harvestFromSeed(seed: seed, quote: _quote());
      await first.updateReview(
          fruitId: fruit.id, memo: '좋았다', fidelityScore: 4);

      final second = InMemoryFruitRepository(store: store);
      await second.load();

      final fruits = await second.getFruits();
      expect(fruits.length, 1);
      expect(fruits.single.memo, '좋았다');
      expect(fruits.single.fidelityScore, 4);
      expect(fruits.single.isReviewed, isTrue);
    });
  });

  group('settings persistence (#122)', () {
    test('settings survive a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await PrefsLocalStore.create();
      final first = InMemorySettingsRepository(store: store);
      await first.load();
      await first.updateSeedTime('07:30');
      await first.setNotifyEnabled(false);
      await first.setThemeMode('dark');
      await first.setFruitRainEnabled(false);

      final second = InMemorySettingsRepository(store: store);
      await second.load();

      final settings = await second.getSettings();
      expect(settings.seedTime, '07:30');
      expect(settings.notifyEnabled, isFalse);
      expect(settings.themeMode, 'dark');
      expect(settings.fruitRainEnabled, isFalse);
    });

    test('empty store keeps the defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await PrefsLocalStore.create();
      final repo = InMemorySettingsRepository(store: store);
      await repo.load();

      final settings = await repo.getSettings();
      expect(settings.seedTime, '08:00');
      expect(settings.notifyEnabled, isTrue);
    });
  });
}
