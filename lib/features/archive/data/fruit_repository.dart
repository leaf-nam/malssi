import 'package:malssi/core/services/debug_clock.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/domain/seed.dart';

abstract class FruitRepository {
  /// 씨앗 개봉 시 열매를 수확한다. 명언 텍스트/저자는 수확 시점 스냅샷이다.
  Future<Fruit> harvestFromSeed({required Seed seed, required Quote quote});

  Future<List<Fruit>> getFruits();

  /// 수확일 내림차순 스트림.
  Stream<List<Fruit>> getFruitsStream();

  /// 후기·점수를 저장한다. 점수는 0~5 (`0` = 미평가), 범위를 벗어나면 [ArgumentError].
  Future<Fruit> updateReview({
    required String fruitId,
    required String memo,
    required int fidelityScore,
  });

  /// 이월 만료 (#113): 오늘 이전에 수확된 미후기 열매를 폐기한다.
  /// 다음날 씨앗 도착까지 후기를 남기지 않으면 정원에 보관되지 않는다.
  /// 후기를 남긴 열매는 유지된다.
  Future<void> pruneUnreviewedBeforeToday();

  /// 디버그용: 저장소 시각을 [by]만큼 앞당긴다 (날짜 이동, #95).
  Future<void> debugShiftTime(Duration by);
}

/// Firestore 연동 전까지 사용하는 인메모리 구현. 영속성 없음.
class InMemoryFruitRepository implements FruitRepository {
  InMemoryFruitRepository({DateTime Function()? clock})
      : _clock = clock ?? DebugClock.now;

  DateTime Function() _clock;
  final List<Fruit> _fruits = [];

  @override
  Future<Fruit> harvestFromSeed(
      {required Seed seed, required Quote quote}) async {
    final fruit = Fruit(
      id: 'fruit-${seed.id}',
      seedId: seed.id,
      quoteId: quote.id,
      text: quote.text,
      author: quote.author,
      harvestedAt: _clock(),
      theme: quote.theme,
    );
    _fruits.add(fruit);
    return fruit;
  }

  List<Fruit> _sortedDesc() {
    final sorted = List<Fruit>.of(_fruits)
      ..sort((a, b) => b.harvestedAt.compareTo(a.harvestedAt));
    return List.unmodifiable(sorted);
  }

  @override
  Future<List<Fruit>> getFruits() async => _sortedDesc();

  @override
  Stream<List<Fruit>> getFruitsStream() => Stream.value(_sortedDesc());

  @override
  Future<Fruit> updateReview({
    required String fruitId,
    required String memo,
    required int fidelityScore,
  }) async {
    if (fidelityScore < 0 || fidelityScore > 5) {
      throw ArgumentError(
          'fidelityScore must be 0..5: $fidelityScore');
    }
    final index = _fruits.indexWhere((f) => f.id == fruitId);
    if (index == -1) {
      throw StateError('Fruit not found: $fruitId');
    }
    final updated = _fruits[index]
        .copyWith(memo: memo, fidelityScore: fidelityScore);
    _fruits[index] = updated;
    return updated;
  }

  @override
  Future<void> pruneUnreviewedBeforeToday() async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    _fruits.removeWhere((fruit) {
      if (fruit.isReviewed) return false;
      final harvested = fruit.harvestedAt;
      final day =
          DateTime(harvested.year, harvested.month, harvested.day);
      return day.isBefore(today);
    });
  }

  @override
  Future<void> debugShiftTime(Duration by) async {
    final base = _clock;
    _clock = () => base().add(by);
  }
}
