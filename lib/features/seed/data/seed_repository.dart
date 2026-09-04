import 'dart:math';

import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/domain/seed.dart';

abstract class SeedRepository {
  /// 오늘 날짜의 씨앗을 반환한다. 없으면 생성한다.
  /// 미심김(`locked`) 씨앗만 자정에 만료시킨다. `growing` 씨앗은 이월된다.
  Future<Seed> getTodaySeed();

  /// 진행 중인 씨앗: `growing` 중 최신 1개 → 미수확 `complete` 최신 1개 →
  /// 없으면 오늘 씨앗. 성장 갱신을 먼저 수행한다.
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
    final now = _clock();
    return _seeds.putIfAbsent(
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
  }

  @override
  Future<Seed> getActiveSeed() async {
    await refreshGrowth();
    final growing = _seeds.values
        .where((s) => s.isGrowing)
        .toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    if (growing.isNotEmpty) return growing.first;
    final complete = _seeds.values
        .where((s) => s.isComplete)
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
    final planted = seed.copyWith(
      quoteId: quote.id,
      status: SeedStatus.growing,
      growthStage: 0,
      plantedAt: _clock(),
    );
    _seeds[seedId] = planted;
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
}
