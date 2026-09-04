import 'dart:math';

import 'package:malssi/core/constants/seed_themes.dart';
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
///
/// 일자별 씨앗 테마는 **랜덤**으로 부여한다 (중복 허용, 2026-09-04 확정).
/// [themePicker]를 주면 테마 선택을 고정할 수 있다 (테스트용).
class InMemorySeedRepository implements SeedRepository {
  InMemorySeedRepository({DateTime Function()? clock, String Function()? themePicker})
      : _clock = clock ?? DateTime.now,
        _themePicker = themePicker ?? _randomTheme;

  final DateTime Function() _clock;
  final String Function() _themePicker;
  final Map<String, Seed> _seeds = {};

  static String _randomTheme() {
    final values = SeedTheme.values;
    return values[Random().nextInt(values.length)];
  }

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
        theme: _themePicker(),
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
