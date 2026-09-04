import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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
}) {
  return repo.harvestFromSeed(
    seed: Seed(
      id: seedId,
      dateKey: seedId,
      quoteId: 'q',
      status: SeedStatus.opened,
      createdAt: at,
    ),
    quote: Quote(
      id: 'q',
      text: text,
      author: '작자',
      likes: 0,
      createdAt: at,
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
      );
      final restored = Fruit.fromMap(
          fruit.toMap()..['harvestedAt'] = _FakeTimestamp());

      expect(restored.id, fruit.id);
      expect(restored.seedId, fruit.seedId);
      expect(restored.text, fruit.text);
      expect(restored.author, fruit.author);
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
  });

  group('ArchiveScreen', () {
    testWidgets('empty state guides to the seed tab', (tester) async {
      final provider = ArchiveProvider(
          fruitRepository: InMemoryFruitRepository());
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('아직 수확한 열매가 없어요'), findsOneWidget);
      expect(find.text('씨앗 탭에서 오늘의 씨앗을 깨보세요'), findsOneWidget);
    });

    testWidgets('shows harvested fruits newest first', (tester) async {
      var now = DateTime(2026, 9, 3, 12);
      final repo = InMemoryFruitRepository(clock: () => now);
      await _harvest(repo, seedId: '2026-09-03', text: '어제 열매', at: now);
      now = DateTime(2026, 9, 4, 12);
      await _harvest(repo, seedId: '2026-09-04', text: '오늘 열매', at: now);
      final provider = ArchiveProvider(fruitRepository: repo);
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.textContaining('어제 열매'), findsOneWidget);
      expect(find.textContaining('오늘 열매'), findsOneWidget);
      // 날짜 표시 확인 (2026.09.04 / 2026.09.03)
      expect(find.text('2026.09.04'), findsOneWidget);
      expect(find.text('2026.09.03'), findsOneWidget);
    });
  });
}

/// `Fruit.fromMap`의 `harvestedAt.toDate()` 호출용 가짜 Timestamp.
class _FakeTimestamp {
  DateTime toDate() => DateTime(2026, 9, 4, 12);
}
