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
