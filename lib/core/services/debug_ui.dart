import 'package:flutter/foundation.dart';

/// 스크린샷용 디버그 UI 표시 여부.
///
/// 디버그 버튼(`디버그: +1단계` 등)은 기본적으로 `kDebugMode`에서만 보인다.
/// 가리는 방법은 두 가지이다:
/// 1. 실행 옵션: `flutter run --dart-define=HIDE_DEBUG_UI=true`
/// 2. 설정 탭의 `디버그 버튼 숨기기` 스위치 (디버그 모드에서만 보임).
///    씨앗 수확 등 디버그 버튼이 필요할 때는 끄고, 스크린샷을 찍을 때 켠다.
abstract class DebugUi {
  /// `--dart-define=HIDE_DEBUG_UI=true`로 실행하면 `true`.
  static const hideButtons = bool.fromEnvironment('HIDE_DEBUG_UI');

  /// 디버그 버튼을 그릴지 여부. 테스트 기본값은 `kDebugMode`와 같다.
  static bool get showButtons => kDebugMode && !hideButtons;
}

/// 디버그 버튼 런타임 숨김 상태. `AppShell`의 `MultiProvider`에서 제공한다.
///
/// 기존 화면의 `provider` + `ChangeNotifier` + `context.watch` 패턴을 따른다.
/// 릴리즈에서는 스위치 자체가 보이지 않으므로 값이 바뀌지 않는다.
class DebugUiProvider extends ChangeNotifier {
  /// `true`이면 디버그 버튼을 그리지 않는다 (스크린샷용).
  bool _hideButtons = false;

  bool get hideButtons => _hideButtons;

  /// 실행 옵션과 런타임 스위치를 합친 최종 표시 여부.
  bool get showButtons => DebugUi.showButtons && !_hideButtons;

  void setHideButtons(bool value) {
    if (_hideButtons == value) return;
    _hideButtons = value;
    notifyListeners();
  }
}
