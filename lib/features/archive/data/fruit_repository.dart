import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/domain/seed.dart';

abstract class FruitRepository {
  /// 씨앗 개봉 시 열매를 수확한다. 명언 텍스트/저자는 수확 시점 스냅샷이다.
  Future<Fruit> harvestFromSeed({required Seed seed, required Quote quote});

  Future<List<Fruit>> getFruits();

  /// 수확일 내림차순 스트림.
  Stream<List<Fruit>> getFruitsStream();
}

/// Firestore 연동 전까지 사용하는 인메모리 구현. 영속성 없음.
class InMemoryFruitRepository implements FruitRepository {
  InMemoryFruitRepository({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
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
}
