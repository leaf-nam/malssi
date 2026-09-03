import 'package:flutter/material.dart';

/// MVP mockup palette: dark ink background, serif quotes, gold accents.
class AppTheme {
  static const Color ink900 = Color(0xFF171B24);
  static const Color ink850 = Color(0xFF1C202B);
  static const Color ink800 = Color(0xFF20242F);
  static const Color ink700 = Color(0xFF2A2F3D);
  static const Color paper = Color(0xFFEFE9DD);
  static const Color paperDim = Color(0xFFC9C4B6);
  static const Color muted = Color(0xFF8B92A3);
  static const Color gold = Color(0xFFD9A94F);
  static const Color goldDim = Color(0xFF8C7238);
  static const Color sage = Color(0xFF7C9885);
  static const Color line = Color(0xFF333847);

  /// Bundled serif (assets/fonts/NotoSerifKR.ttf) — no runtime download,
  /// since the macOS sandbox blocks the google_fonts HTTP fetch.
  static TextStyle quoteTextStyle({double fontSize = 21}) =>
      TextStyle(
        fontFamily: 'NotoSerifKR',
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
      appBarTheme: const AppBarTheme(
        backgroundColor: ink900,
        foregroundColor: paper,
        elevation: 0,
        titleTextStyle: TextStyle(
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
            const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
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
        selectedLabelStyle: TextStyle(fontSize: 9.5),
        unselectedLabelStyle: TextStyle(fontSize: 9.5),
      ),
    );
  }

  /// Light theme kept for compatibility; the MVP uses [dark].
  static ThemeData light() => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: Colors.grey[50],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.indigo),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            )),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
}
