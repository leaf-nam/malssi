import 'package:flutter/material.dart';

class AppTheme {
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

  static ThemeData dark() => ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
      );
}
