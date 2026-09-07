import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 온보딩에서 쓰는 앱 스크린샷이 에셋 번들에 들어가는지 보장한다.
///
/// `assets/images/` 하위 폴더는 pubspec에 명시해야 번들에 포함되므로,
/// 스크린샷을 추가·변경·삭제할 때 이 테스트가 깨지면
/// `pubspec.yaml`의 assets와 `onboardingPages`를 함께 고친다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all onboarding screenshots load from the asset bundle', () async {
    const paths = [
      'assets/images/screenshots/seed_locked.png',
      'assets/images/screenshots/seed_growing.png',
      'assets/images/screenshots/fruit_complete.png',
      'assets/images/screenshots/review_empty.png',
      'assets/images/screenshots/review_filled.png',
      'assets/images/screenshots/archive_garden.png',
      'assets/images/screenshots/settings.png',
      'assets/images/screenshots/settings_seed_time.png',
    ];
    for (final path in paths) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });
}
