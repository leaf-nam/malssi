import 'package:shared_preferences/shared_preferences.dart';

/// 첫 실행 도움말(온보딩) 완료 상태 저장소 (#130).
///
/// Firestore를 사용하지 않는 순수 로컬 상태이다. 따라서
/// `CollectionNames`에 키를 두지 않고 본 파일의 [OnboardingRepository]
/// 정적 상수로 관리한다 (#122 로컬 지속화 방식 계승).
abstract class OnboardingRepository {
  /// `SharedPreferences`에 쓰는 완료 플래그 키.
  static const completedKey = 'onboarding_completed';

  Future<bool> isCompleted();

  Future<void> complete();

  /// 설정 탭 "다시 보기" 검증·테스트용. 실사용 플로우에서는 쓰지 않는다.
  Future<void> reset();
}

/// `SharedPreferences` 기반 구현. `prefs`가 `null`이면 순수 인메모리로
/// 동작한다 (위젯 테스트 기본값).
class PrefsOnboardingRepository implements OnboardingRepository {
  PrefsOnboardingRepository({this._prefs, this._completed = false});

  final SharedPreferences? _prefs;
  bool _completed;

  @override
  Future<bool> isCompleted() async {
    final prefs = _prefs;
    if (prefs == null) return _completed;
    return prefs.getBool(OnboardingRepository.completedKey) ?? false;
  }

  @override
  Future<void> complete() async {
    final prefs = _prefs;
    if (prefs == null) {
      _completed = true;
      return;
    }
    await prefs.setBool(OnboardingRepository.completedKey, true);
  }

  @override
  Future<void> reset() async {
    final prefs = _prefs;
    if (prefs == null) {
      _completed = false;
      return;
    }
    await prefs.setBool(OnboardingRepository.completedKey, false);
  }
}
