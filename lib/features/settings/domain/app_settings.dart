class AppSettings {
  final String seedTime;
  final bool notifyEnabled;

  /// 화면 모드: `'light'` / `'dark'` / `'system'` 중 1개.
  final String themeMode;

  const AppSettings({
    required this.seedTime,
    required this.notifyEnabled,
    this.themeMode = defaultThemeMode,
  });

  static const defaultSeedTime = '08:00';

  static const defaultThemeMode = 'system';

  static const validThemeModes = ['light', 'dark', 'system'];

  /// `'HH:mm'` 형식 검증.
  static bool isValidSeedTime(String value) =>
      _timePattern.hasMatch(value);

  static bool isValidThemeMode(String value) =>
      validThemeModes.contains(value);

  static final RegExp _timePattern =
      RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  int get seedHour => int.parse(seedTime.split(':')[0]);
  int get seedMinute => int.parse(seedTime.split(':')[1]);

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final themeMode = map['themeMode'];
    return AppSettings(
      seedTime: map['seedTime'] ?? defaultSeedTime,
      notifyEnabled: map['notifyEnabled'] ?? true,
      themeMode: themeMode is String && isValidThemeMode(themeMode)
          ? themeMode
          : defaultThemeMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seedTime': seedTime,
      'notifyEnabled': notifyEnabled,
      'themeMode': themeMode,
    };
  }

  AppSettings copyWith(
      {String? seedTime, bool? notifyEnabled, String? themeMode}) {
    return AppSettings(
      seedTime: seedTime ?? this.seedTime,
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
