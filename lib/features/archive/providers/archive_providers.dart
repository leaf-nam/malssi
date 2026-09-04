import 'package:flutter/foundation.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/archive/domain/fruit.dart';

/// 보관 탭 상태. `provider` + [ChangeNotifier] 패턴 (컨벤션 §3).
class ArchiveProvider extends ChangeNotifier {
  ArchiveProvider({required this._fruitRepository});

  final FruitRepository _fruitRepository;

  List<Fruit> _fruits = List.unmodifiable(const <Fruit>[]);
  List<Fruit> get fruits => _fruits;

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
}
