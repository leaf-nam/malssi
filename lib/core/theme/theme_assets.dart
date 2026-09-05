import 'package:flutter/material.dart';
import 'package:malssi/core/constants/seed_themes.dart';

/// 테마별 표시 요소 (에셋 경로·한글명) 매핑.
/// `assets/images/`에 등록된 이미지 기준 (`model_spec.md` §4.11).
/// 알 수 없는 테마는 빈 문자열/기본 문구를 반환하고, 호출 측에서 폴백한다.
abstract class ThemeAssets {
  static const _fruits = {
    SeedTheme.vitality: 'strawberry',
    SeedTheme.happiness: 'orange',
    SeedTheme.growth: 'lemon',
    SeedTheme.health: 'kiwi',
    SeedTheme.peace: 'blueberry',
    SeedTheme.relationship: 'grape',
    SeedTheme.wisdom: 'grapefruit',
  };

  static const labels = {
    SeedTheme.vitality: '활력',
    SeedTheme.happiness: '행복',
    SeedTheme.growth: '성장',
    SeedTheme.health: '건강',
    SeedTheme.peace: '평온',
    SeedTheme.relationship: '관계',
    SeedTheme.wisdom: '지혜',
  };

  /// 열매 이미지 (`assets/images/<이름>.png`). 미등록 테마는 `''`.
  static String fruitImage(String theme) {
    final name = _fruits[theme];
    if (name == null) return '';
    return 'assets/images/$name.png';
  }

  /// 씨앗 이미지 (`assets/images/<이름>_seed.png`). 미등록 테마는 `''`.
  static String seedImage(String theme) {
    final name = _fruits[theme];
    if (name == null) return '';
    return 'assets/images/${name}_seed.png';
  }

  /// 한글 테마명. 미등록 테마는 `'오늘의 씨앗'`.
  static String labelOf(String theme) => labels[theme] ?? '오늘의 씨앗';

  /// 성장 단계 이미지 (#40, #67 — 과일별 5단계 에셋).
  /// - 0단계: 테마 씨앗 이미지 (`<이름>_seed.png`).
  /// - 1~5단계: `<이름>-<n>.png` (7종×5단계, 2026-09-05 확보).
  /// 미등록 테마는 `''` (호출 측 폴백).
  static String growthImage(String theme, int stage) {
    final name = _fruits[theme];
    if (name == null) return seedImage(theme);
    if (stage <= 0) return seedImage(theme);
    return 'assets/images/$name-$stage.png';
  }

  /// 잔디 그리드 셀 색상. 다크 7종 (#39) + 라이트 밝은 7종 (#56).
  /// [brightness]에 따라 다크톤/밝은톤을 반환한다. 미등록 테마는 회색.
  static Color cellColor(String theme,
      [Brightness brightness = Brightness.dark]) {
    final cells =
        brightness == Brightness.light ? _lightCells : _darkCells;
    return cells[theme] ?? _fallbackCell(brightness);
  }

  /// 다크톤 7종 (#39).
  static const _darkCells = {
    SeedTheme.vitality: Color(0xFFA03236),
    SeedTheme.happiness: Color(0xFFAC6F08),
    SeedTheme.growth: Color(0xFFA47D06),
    SeedTheme.health: Color(0xFF188A42),
    SeedTheme.peace: Color(0xFF295BAC),
    SeedTheme.relationship: Color(0xFF4547A9),
    SeedTheme.wisdom: Color(0xFFA5326B),
  };

  /// 라이트용 밝은 열매 7종 (#56).
  static const _lightCells = {
    SeedTheme.vitality: Color(0xFFE35D6A),
    SeedTheme.happiness: Color(0xFFF2994A),
    SeedTheme.growth: Color(0xFFF2C94C),
    SeedTheme.health: Color(0xFF6FCF97),
    SeedTheme.peace: Color(0xFF5B8DEF),
    SeedTheme.relationship: Color(0xFF9B7EDE),
    SeedTheme.wisdom: Color(0xFFF0618F),
  };

  static Color _fallbackCell(Brightness brightness) =>
      brightness == Brightness.light
          ? const Color(0xFFD8D2C7)
          : const Color(0xFF6C707E);

  /// 잔디 그리드 규격 (#72).
  static const grassWeeks = 53;
  static const grassGap = 4.0;
  static const grassMinCell = 22.0;
  static const grassMaxCell = 30.0;

  /// [maxWidth]에 53주 전체가 최소 칸 이상으로 들어가면 `true` (스크롤 불필요).
  static bool grassFitsAll(double maxWidth) =>
      ((maxWidth - (grassWeeks - 1) * grassGap) / grassWeeks) >=
      grassMinCell;

  /// 전체 맞춤 모드의 칸 크기 (최대치로 상한, 남는 폭은 중앙 정렬).
  static double grassFitCell(double maxWidth) =>
      (((maxWidth - (grassWeeks - 1) * grassGap) / grassWeeks))
          .clamp(grassMinCell, grassMaxCell);

  /// 스크롤 모드에서 한 화면에 온전히 보이는 주 수 (#83).
  /// 정지 상태에서 양쪽 가장자리에 반칸이 생기지 않게,
  /// 이 주 수에 딱 맞게 칸을 키운다.
  static int grassVisibleWeeks(double maxWidth) {
    final n = (maxWidth / (grassMinCell + grassGap)).floor();
    return n < 1 ? 1 : n;
  }

  /// 스크롤 모드 칸 크기: [grassVisibleWeeks]개 주가 폭에 정확히 맞는다 (#83).
  static double grassScrollCell(double maxWidth) {
    final n = grassVisibleWeeks(maxWidth);
    return (maxWidth - (n - 1) * grassGap) / n;
  }
}
