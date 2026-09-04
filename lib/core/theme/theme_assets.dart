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

  /// 성장 단계 이미지 (#40, 혼합 전략).
  /// - 0~2단계: 공용 `growth_<n>.png` (없으면 테마 씨앗 이미지로 폴백).
  /// - 3~4단계: 테마별 `growth_<이름>_<n>.png` (없으면 테마 씨앗 이미지로 폴백).
  /// - 5단계(열매): 기존 테마 열매 이미지 재사용.
  /// 미등록 테마는 `''` (호출 측 폴백).
  static String growthImage(String theme, int stage) {
    if (stage >= 5) return fruitImage(theme);
    if (stage <= 2) return 'assets/images/growth_$stage.png';
    final name = _fruits[theme];
    if (name == null) return seedImage(theme);
    return 'assets/images/growth_${name}_$stage.png';
  }

  /// 잔디 그리드 셀 색상. 다크톤 7종 (#39). 미등록 테마는 회색.
  static Color cellColor(String theme) {
    switch (theme) {
      case SeedTheme.vitality:
        return const Color(0xFFA03236);
      case SeedTheme.happiness:
        return const Color(0xFFAC6F08);
      case SeedTheme.growth:
        return const Color(0xFFA47D06);
      case SeedTheme.health:
        return const Color(0xFF188A42);
      case SeedTheme.peace:
        return const Color(0xFF295BAC);
      case SeedTheme.relationship:
        return const Color(0xFF4547A9);
      case SeedTheme.wisdom:
        return const Color(0xFFA5326B);
      default:
        return const Color(0xFF6C707E);
    }
  }
}
