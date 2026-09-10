import 'dart:math';

import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/core/services/debug_clock.dart';
import 'package:malssi/core/services/local_store.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/domain/seed.dart';

abstract class SeedRepository {
  /// 오늘 날짜의 씨앗을 반환한다. 없으면 생성한다.
  /// 미심김(`locked`) 씨앗만 자정에 만료시킨다. `growing` 씨앗은 이월된다.
  Future<Seed> getTodaySeed();

  /// 진행 중인 씨앗: `growing` 중 최신 1개 → 당일 `complete` 최신 1개 →
  /// 없으면 오늘 씨앗. 성장 갱신을 먼저 수행한다.
  /// 일자 변경선 (#109): 지난 `complete`는 오늘 씨앗에 양보한다.
  Future<Seed> getActiveSeed();

  Stream<List<Seed>> getSeedsStream();

  /// 씨앗을 개봉하고 명언을 확정한다.
  /// 이미 개봉/만료된 씨앗이면 [StateError]를 던진다.
  Future<Seed> openSeed({required String seedId, required Quote quote});

  /// 씨앗을 심는다 (`locked` → `growing`). 테마에 맞는 명언을 확정한다.
  /// 잠금 상태가 아니면 [StateError]를 던진다.
  Future<Seed> plantSeed({required String seedId, required Quote quote});

  /// `growing` 씨앗들의 단계를 경과 시간에 맞춰 갱신한다.
  /// 최종 단계 도달 시 `complete`로 전환한다.
  Future<void> refreshGrowth();

  /// 디버그용: 심은 시각을 [by]만큼 앞당긴다 (성장 빨리감기).
  Future<Seed> debugFastForward(
      {required String seedId, required Duration by});

  /// 디버그용: 저장소 시각을 [by]만큼 앞당긴다 (날짜 이동, #95).
  Future<void> debugShiftTime(Duration by);
}

/// 로컬 저장(`LocalStore`) 기반 인메모리 구현. 서버 동기화는 미계획.
///
/// 일자별 씨앗 테마는 **랜덤**으로 부여한다 (중복 허용, 2026-09-04 확정).
/// [themePicker]를 주면 테마 선택을 고정할 수 있다 (테스트용).
class InMemorySeedRepository implements SeedRepository {
  InMemorySeedRepository(
      {DateTime Function()? clock,
      String Function()? themePicker,
      this._store})
      : _clock = clock ?? DebugClock.now,
        _themePicker = themePicker ?? _randomTheme;

  DateTime Function() _clock;
  final String Function() _themePicker;
  final Map<String, Seed> _seeds = {};

  /// 로컬 저장소 (#122). `null`이면 순수 인메모리로 동작한다 (테스트 기본값).
  final LocalStore? _store;

  static const _dateKeys = {'createdAt', 'plantedAt'};

  /// 저장된 씨앗들을 불러온다. 저장소 미연결·빈 저장소에서는 아무 일도 없다.
  /// `main()` 시작 시 1회 호출한다.
  Future<void> load() async {
    final store = _store;
    if (store == null) return;
    final raws = await store.readList(StoreKeys.seeds);
    _seeds
      ..clear()
      ..addEntries(raws.map((raw) {
        final seed = Seed.fromMap(decodeDates(raw, _dateKeys));
        return MapEntry(seed.id, seed);
      }));
  }

  Future<void> _persist() async {
    final store = _store;
    if (store == null) return;
    await store.writeList(StoreKeys.seeds, [
      for (final seed in _seeds.values)
        encodeDates(seed.toMap(), _dateKeys),
    ]);
  }

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
    final now = _clock();
    var seed = _seeds.putIfAbsent(
      todayKey,
      () {
        final createdAt = now;
        return Seed(
          id: todayKey,
          dateKey: todayKey,
          quoteId: '',
          status: SeedStatus.locked,
          createdAt: createdAt,
          theme: _themePicker(),
          plantedAt: createdAt,
        );
      },
    );
    // 정오 마감 (#147): 당일 미심김 씨앗은 정오가 지나면 만료된다.
    if (seed.isMissed(now)) {
      seed = seed.copyWith(status: SeedStatus.expired);
      _seeds[todayKey] = seed;
    }
    await _persist();
    return seed;
  }

  @override
  Future<Seed> getActiveSeed() async {
    await refreshGrowth();
    final growing = _seeds.values
        .where((s) => s.isGrowing)
        .toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    if (growing.isNotEmpty) return growing.first;
    // 일자 변경선 (#109): 당일 완성이면 표시하고,
    // 지난 완성이면 오늘 씨앗에 양보한다.
    final todayKey = Seed.dateKeyFor(_clock());
    final complete = _seeds.values
        .where((s) => s.isComplete && s.dateKey == todayKey)
        .toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    if (complete.isNotEmpty) return complete.first;
    return getTodaySeed();
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
    await _persist();
    return opened;
  }

  @override
  Future<Seed> plantSeed(
      {required String seedId, required Quote quote}) async {
    final seed = _seeds[seedId];
    if (seed == null) {
      throw StateError('Seed not found: $seedId');
    }
    if (!seed.isLocked) {
      throw StateError('Seed is not locked: $seedId (${seed.status})');
    }
    if (seed.isMissed(_clock())) {
      throw StateError('Seed missed the noon deadline: $seedId');
    }
    final planted = seed.copyWith(
      quoteId: quote.id,
      status: SeedStatus.growing,
      growthStage: 0,
      plantedAt: _clock(),
    );
    _seeds[seedId] = planted;
    await _persist();
    return planted;
  }

  @override
  Future<void> refreshGrowth() async {
    final now = _clock();
    for (final entry in _seeds.entries.toList()) {
      final seed = entry.value;
      if (!seed.isGrowing) continue;
      final stage = seed.growthStageAt(now);
      _seeds[entry.key] = seed.copyWith(
        growthStage: stage,
        status: stage >= Seed.maxGrowthStage
            ? SeedStatus.complete
            : SeedStatus.growing,
      );
    }
    await _persist();
  }

  @override
  Future<Seed> debugFastForward(
      {required String seedId, required Duration by}) async {
    final seed = _seeds[seedId];
    if (seed == null) {
      throw StateError('Seed not found: $seedId');
    }
    final shifted =
        seed.copyWith(plantedAt: seed.plantedAt.subtract(by));
    _seeds[seedId] = shifted;
    await refreshGrowth();
    return _seeds[seedId]!;
  }

  @override
  Future<void> debugShiftTime(Duration by) async {
    final base = _clock;
    _clock = () => base().add(by);
  }
}
