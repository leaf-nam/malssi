import 'package:flutter/foundation.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/archive/domain/theme_stat.dart';

/// 보관 탭 상태. `provider` + [ChangeNotifier] 패턴 (컨벤션 §3).
class ArchiveProvider extends ChangeNotifier {
  ArchiveProvider({required this._fruitRepository});

  final FruitRepository _fruitRepository;

  List<Fruit> _fruits = List.unmodifiable(const <Fruit>[]);
  List<Fruit> get fruits => _fruits;

  /// 수확일 날짜키(`'YYYY-MM-DD'`) → 열매. 잔디 그리드의 칸 조회용.
  Map<String, Fruit> get fruitsByDateKey => {
        for (final fruit in _fruits) fruit.harvestDateKey: fruit,
      };

  /// 잔디에 심어진 열매 = 리뷰를 남긴 열매만 (#65).
  List<Fruit> get plantedFruits =>
      List.unmodifiable(_fruits.where((f) => f.isReviewed));

  /// 심어진 열매의 날짜키 → 열매. 잔디 그리드 표시용.
  Map<String, Fruit> get plantedByDateKey => {
        for (final fruit in plantedFruits) fruit.harvestDateKey: fruit,
      };

  /// 테마별 심어진 개수 (내림차순, #88). 최다 색깔(#89) 선정에 재사용한다.
  /// 테마 미분류(`''`)는 제외한다.
  /// 동률이면 테마 정의 순서(`SeedTheme.values`)로 안정 정렬한다 (#273).
  Map<String, int> get themeCounts {
    final counts = <String, int>{};
    for (final fruit in plantedFruits) {
      if (fruit.theme.isEmpty) continue;
      counts[fruit.theme] = (counts[fruit.theme] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        final byOrder =
            ThemeStat.orderOf(a.key).compareTo(ThemeStat.orderOf(b.key));
        if (byOrder != 0) return byOrder;
        return a.key.compareTo(b.key);
      });
    return Map.fromEntries(entries);
  }

  /// 색깔별 개수·비율 통계 (#273). 개수 내림차순, 동률은 테마 정의 순서.
  /// 정수 비율은 최대잔여법으로 배분해 합이 100이 되게 한다.
  List<ThemeStat> get themeStats {
    final counts = themeCounts;
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) return const <ThemeStat>[];

    final themes = counts.keys.toList();
    final countsList = [for (final theme in themes) counts[theme]!];
    final raw = [for (final count in countsList) count * 100 / total];
    final percents = [for (final value in raw) value.floor()];
    final leftover =
        100 - percents.fold<int>(0, (sum, percent) => sum + percent);

    // 소수부가 큰 항목부터 1%씩 보정한다. 동률이면 현재 정렬 순서를 유지한다.
    final order = List<int>.generate(themes.length, (index) => index)
      ..sort((a, b) {
        final byFraction =
            (raw[b] - raw[b].floorToDouble()).compareTo(
          raw[a] - raw[a].floorToDouble(),
        );
        return byFraction != 0 ? byFraction : a.compareTo(b);
      });
    for (var i = 0; i < leftover; i++) {
      percents[order[i % order.length]]++;
    }

    return List.unmodifiable([
      for (var i = 0; i < themes.length; i++)
        ThemeStat(
          theme: themes[i],
          count: countsList[i],
          percent: percents[i],
          ratio: countsList[i] / total,
        ),
    ]);
  }

  /// 색깔이 분류된 열매 총 개수. 비율의 분모와 같다 (#273).
  int get themeTotal =>
      themeCounts.values.fold<int>(0, (sum, count) => sum + count);

  /// 가장 많이 모은 테마. 없으면 `''` (#89).
  String get topTheme =>
      themeCounts.isEmpty ? '' : themeCounts.keys.first;

  /// 심어진 연도 중 가장 이른 연도. 없으면 null (#99).
  int? get firstPlantedYear {
    if (plantedFruits.isEmpty) return null;
    var minYear = plantedFruits.first.harvestedAt.year;
    for (final fruit in plantedFruits) {
      if (fruit.harvestedAt.year < minYear) {
        minYear = fruit.harvestedAt.year;
      }
    }
    return minYear;
  }

  /// [year]년에 심어진 열매 (수확일 기준, #97).
  List<Fruit> plantedInYear(int year) => List.unmodifiable(
      plantedFruits.where((f) => f.harvestedAt.year == year));

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 수확한 열매 목록을 불러온다 (수확일 내림차순).
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _fruits = await _fruitRepository.getFruits();
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 리뷰·점수를 저장하고 목록을 갱신한다.
  Future<void> updateReview({
    required String fruitId,
    required String memo,
    required int fidelityScore,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _fruitRepository.updateReview(
        fruitId: fruitId,
        memo: memo,
        fidelityScore: fidelityScore,
      );
      _fruits = await _fruitRepository.getFruits();
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      notifyListeners();
    }
  }
}
