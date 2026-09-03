import 'package:flutter/foundation.dart';
import 'package:malssi/features/mypage/data/user_repository.dart';

/// Minimal [ChangeNotifier]-based state for the my-page screen.
class UserProfileProvider extends ChangeNotifier {
  UserProfileProvider({required this._repository});

  final UserRepository _repository;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _profile = await _repository.getUserProfile();
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
