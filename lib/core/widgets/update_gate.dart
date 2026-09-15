import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

/// 스토어 업데이트 유도 (#192). `upgrader` 패키지로 Play·App Store 버전을
/// 직접 조회하고 한글 안내창을 띄운다. 백엔드가 필요 없다.
/// - Android: Play 스토어 버전 조회 → 안내창 → 스토어 이동.
/// - iOS: 번들 ID로 App Store 조회 → 안내창 → 스토어 이동.
/// - 권장 모드(닫기 가능). 강제 전환은 `Upgrader(minAppVersion: ...)` 한 줄이면 된다.
/// - 테스트에서는 [enabled]를 `false`로 둔다 (스토어 조회 네트워크 방지).
///   `AppShell(updateCheckEnabled: ...)`로 주입한다.
class UpdateGate extends StatelessWidget {
  const UpdateGate({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;

  /// `false`면 조회 없이 자식을 그대로 보여준다 (테스트용).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return UpgradeAlert(
      upgrader: Upgrader(messages: MalssiUpgraderMessages()),
      child: child,
    );
  }
}

/// 한글 안내 문구 (#192). 기기 언어와 무관하게 항상 한글로 보여준다.
class MalssiUpgraderMessages extends UpgraderMessages {
  MalssiUpgraderMessages() : super(code: 'ko');

  @override
  String? message(UpgraderMessage messageKey) {
    if (languageCode == 'ko') {
      switch (messageKey) {
        case UpgraderMessage.body:
          return '{{appName}}의 새 버전이 있어요!';
        case UpgraderMessage.buttonTitleIgnore:
          return '무시하기';
        case UpgraderMessage.buttonTitleLater:
          return '나중에';
        case UpgraderMessage.buttonTitleUpdate:
          return '지금 업데이트';
        case UpgraderMessage.prompt:
          return '업데이트하시겠어요?';
        case UpgraderMessage.releaseNotes:
          return '새로운 내용';
        case UpgraderMessage.title:
          return '업데이트 안내';
      }
    }
    return super.message(messageKey);
  }
}
