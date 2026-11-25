import 'package:malssi/core/constants/seed_themes.dart';

/// 테마(색깔)별 모은 열매 통계 한 줄 (#273).
///
/// [ratio]는 막대 길이용 원값(0.0~1.0), [percent]는 화면 표시용 정수 비율이다.
/// 정수 비율은 최대잔여법으로 배분해 전체 합이 항상 100이 되게 한다.
class ThemeStat {
  const ThemeStat({
    required this.theme,
    required this.count,
    required this.percent,
    required this.ratio,
  });

  /// `SeedTheme` 정규 키.
  final String theme;

  /// 이 색깔로 모은 열매 개수.
  final int count;

  /// 전체 대비 정수 비율(%). 합은 100이다.
  final int percent;

  /// 전체 대비 원비율(0.0~1.0). 막대 길이에 쓴다.
  final double ratio;

  /// 테마 정의 순서. 알 수 없는 테마는 뒤로 보낸다 (#273 동률 안정 정렬).
  static int orderOf(String theme) {
    final index = SeedTheme.values.indexOf(theme);
    return index == -1 ? SeedTheme.values.length : index;
  }
}
