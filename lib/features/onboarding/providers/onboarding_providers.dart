import 'package:flutter/foundation.dart';
import 'package:malssi/features/onboarding/data/onboarding_repository.dart';

/// 온보딩 완료 상태. 기존 화면의 `provider` + `ChangeNotifier` +
/// `context.watch`/`context.read` 패턴을 따른다 (#130).
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({
    required this._repository,
    this.autoShowOnFirstLaunch = false,
  });

  final OnboardingRepository _repository;

  /// `true`일 때만 3탭 셸이 첫 실행에 `/onboarding`으로 자동 이동한다.
  /// `main()`에서만 `true`로 주입하고, 테스트 기본값은 `false`이다.
  final bool autoShowOnFirstLaunch;

  bool? _completed;
  bool _isLoading = false;
  String? _errorMessage;

  /// `null` = 아직 로드 전.
  bool? get completed => _completed;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _completed = await _repository.isCompleted();
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> complete() async {
    try {
      await _repository.complete();
      _completed = true;
    } catch (e) {
      _errorMessage = '$e';
    }
    notifyListeners();
  }
}
