import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/domain/seed.dart';

abstract class SeedRepository {
  /// 오늘 날짜의 씨앗을 반환한다. 없으면 생성한다.
  /// 자정이 지나 미개봉으로 남은 씨앗은 `expired`로 만료시킨다 (이월 없음).
  Future<Seed> getTodaySeed();

  Stream<List<Seed>> getSeedsStream();

  /// 씨앗을 개봉하고 명언을 확정한다.
  /// 이미 개봉/만료된 씨앗이면 [StateError]를 던진다.
  Future<Seed> openSeed({required String seedId, required Quote quote});
}

/// Firestore 연동 전까지 사용하는 인메모리 구현. 영속성 없음.
class InMemorySeedRepository implements SeedRepository {
  InMemorySeedRepository({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, Seed> _seeds = {};

  @override
  Future<Seed> getTodaySeed() async {
    final todayKey = Seed.dateKeyFor(_clock());
    for (final entry in _seeds.entries) {
      if (entry.key != todayKey && entry.value.isLocked) {
        _seeds[entry.key] =
            entry.value.copyWith(status: SeedStatus.expired);
      }
    }
    return _seeds.putIfAbsent(
      todayKey,
      () => Seed(
        id: todayKey,
        dateKey: todayKey,
        quoteId: '',
        status: SeedStatus.locked,
        createdAt: _clock(),
      ),
    );
  }

  @override
  Stream<List<Seed>> getSeedsStream() =>
      Stream.value(List.unmodifiable(_seeds.values));

  @override
  Future<Seed> openSeed(
      {required String seedId, required Quote quote}) async {
    final seed = _seeds[seedId];
    if (seed == null) {
      throw StateError('Seed not found: $seedId');
    }
    if (!seed.isLocked) {
      throw StateError('Seed is not locked: $seedId (${seed.status})');
    }
    final opened =
        seed.copyWith(quoteId: quote.id, status: SeedStatus.opened);
    _seeds[seedId] = opened;
    return opened;
  }
}
