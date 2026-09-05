import 'package:flutter/foundation.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/archive/domain/fruit.dart';

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

  /// 잔디에 심어진 열매 = 후기를 남긴 열매만 (#65).
  List<Fruit> get plantedFruits =>
      List.unmodifiable(_fruits.where((f) => f.isReviewed));

  /// 심어진 열매의 날짜키 → 열매. 잔디 그리드 표시용.
  Map<String, Fruit> get plantedByDateKey => {
        for (final fruit in plantedFruits) fruit.harvestDateKey: fruit,
      };

  /// 테마별 심어진 개수 (내림차순, #88). 최다 색깔(#89) 선정에 재사용한다.
  /// 테마 미분류(`''`)는 제외한다.
  Map<String, int> get themeCounts {
    final counts = <String, int>{};
    for (final fruit in plantedFruits) {
      if (fruit.theme.isEmpty) continue;
      counts[fruit.theme] = (counts[fruit.theme] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  /// 가장 많이 모은 테마. 없으면 `''` (#89).
  String get topTheme =>
      themeCounts.isEmpty ? '' : themeCounts.keys.first;

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

  /// 후기·점수를 저장하고 목록을 갱신한다.
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
