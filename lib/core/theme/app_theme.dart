import 'package:flutter/material.dart';

/// 앱 톤앤매너: 도트풍 Galmuri11 + 밝은 크림(라이트) / 잉크(다크).
/// - 명언 씨앗 탭(`/`)은 항상 다크 고정 (밝은 모드에서도 잉크 배경).
/// - 나머지 화면은 라이트 기본 + 다크모드 지원 (`ThemeMode.system`).
class AppTheme {
  /// 도트풍 한글 폰트 (Galmuri11, OFL).
  static const String fontFamily = 'Galmuri11';

  // 다크 팔레트 (씨앗 탭 고정 + 다크모드).
  /// 말씨 탭 전용 니어블랙 (#59 — 기본 다크보다 더 어둡게).
  static const Color abyss = Color(0xFF0A0C11);
  static const Color ink900 = Color(0xFF171B24);  static const Color ink850 = Color(0xFF1C202B);
  static const Color ink800 = Color(0xFF20242F);
  static const Color ink700 = Color(0xFF2A2F3D);
  static const Color paper = Color(0xFFEFE9DD);
  static const Color paperDim = Color(0xFFC9C4B6);
  static const Color muted = Color(0xFF8B92A3);
  static const Color gold = Color(0xFFD9A94F);
  static const Color goldDim = Color(0xFF8C7238);
  static const Color sage = Color(0xFF7C9885);
  static const Color line = Color(0xFF333847);

  // 라이트 팔레트 (밝은 크림 베이스).
  static const Color cream = Color(0xFFFFF8EC);
  static const Color creamCard = Color(0xFFFFFFFF);
  static const Color creamLine = Color(0xFFEADFCB);
  static const Color cocoa = Color(0xFF3B3128);
  static const Color cocoaMuted = Color(0xFF97897A);
  static const Color goldDeep = Color(0xFFA86E14);

  // 하단 탭 탭별 배경색 (#75).
  // - 말씨: 배경(abyss)과 동일한 검은색 (양 모드).
  // - 정원: 흙(갈)색. 설정: 회색. 각각 라이트/다크 분리.
  static const Color navGardenLight = Color(0xFFC9A06A);
  static const Color navGardenDark = Color(0xFF4A3423);
  static const Color navSettingsLight = Color(0xFFE3DED2);
  static const Color navSettingsDark = Color(0xFF23262E);

  /// 명언本文. 도트풍 Galmuri11 (기존 NotoSerifKR에서 교체, #32).
  static TextStyle quoteTextStyle({double fontSize = 21}) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: 1.55,
        fontWeight: FontWeight.w500,
        color: paper,
      );

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: ink900,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.dark,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: paper,
        displayColor: paper,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ink900,
        foregroundColor: paper,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: paper,
        ),
      ),
      cardTheme: const CardThemeData(
        color: ink800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(gold),
          foregroundColor: WidgetStateProperty.all(const Color(0xFF211705)),
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          )),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
                fontFamily: fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w700),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ink800,
        hintStyle: const TextStyle(color: muted, fontSize: 12.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: line),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ink900,
        selectedItemColor: gold,
        unselectedItemColor: muted,
        selectedLabelStyle: TextStyle(fontSize: 12.5),
        unselectedLabelStyle: TextStyle(fontSize: 12.5),
      ),
    );
  }

  /// Light theme kept for compatibility; the MVP uses [dark].
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: cream,
      dividerColor: creamLine,
      colorScheme: ColorScheme.fromSeed(
        seedColor: goldDeep,
        brightness: Brightness.light,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: cocoa,
        displayColor: cocoa,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: cocoa,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: cocoa,
        ),
      ),
      cardTheme: const CardThemeData(
        color: creamCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: creamLine),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(gold),
          foregroundColor: WidgetStateProperty.all(const Color(0xFF211705)),
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          )),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
                fontFamily: fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w700),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: creamCard,
        hintStyle: const TextStyle(color: cocoaMuted, fontSize: 12.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: creamLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: creamLine),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cream,
        selectedItemColor: goldDeep,
        unselectedItemColor: cocoaMuted,
        selectedLabelStyle: TextStyle(fontSize: 12.5),
        unselectedLabelStyle: TextStyle(fontSize: 12.5),
      ),
    );
  }
}
