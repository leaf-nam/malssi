class AppSettings {
  final String seedTime;
  final bool notifyEnabled;

  /// 화면 모드: `'light'` / `'dark'` / `'system'` 중 1개.
  final String themeMode;

  /// 열매 비 효과 표시 여부 (#108). 기본값 on.
  final bool fruitRainEnabled;

  /// 성장 단계 도달 알림 여부 (#244). 기본값 off (하루 최대 4건이라 opt-in).
  final bool growthNotifyEnabled;

  /// 잠금 해제 시 오늘의 말씨 먼저 보기 (#253, Android만).
  /// 씨앗 도착 일일 알림에 full-screen intent를 붙인다. 기본값 off (opt-in).
  final bool lockscreenFirstEnabled;

  const AppSettings({
    required this.seedTime,
    required this.notifyEnabled,
    this.themeMode = defaultThemeMode,
    this.fruitRainEnabled = defaultFruitRainEnabled,
    this.growthNotifyEnabled = defaultGrowthNotifyEnabled,
    this.lockscreenFirstEnabled = defaultLockscreenFirstEnabled,
  });

  static const defaultSeedTime = '08:00';

  /// 씨앗 생성 시간 상한(시). 당일 마감 14시와 같은 값 (#147, #159).
  /// `Seed.deadlineHour`와 함께 바뀌어야 한다.
  static const maxSeedTimeHour = 14;

  static const defaultThemeMode = 'system';

  static const defaultFruitRainEnabled = true;

  static const defaultGrowthNotifyEnabled = true;

  static const defaultLockscreenFirstEnabled = false;

  static const validThemeModes = ['light', 'dark', 'system'];

  /// `'HH:mm'` 형식 검증.
  static bool isValidSeedTime(String value) =>
      _timePattern.hasMatch(value);

  /// 씨앗 생성 시간으로 허용되는지 (#159). 마감 14시 정각까지 허용하고,
  /// 그 이후는 막는다. 형식이 틀리면 `false`.
  static bool isAllowedSeedTime(String value) {
    if (!isValidSeedTime(value)) return false;
    final parts = value.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    if (hour < maxSeedTimeHour) return true;
    return hour == maxSeedTimeHour && minute == 0;
  }

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
      fruitRainEnabled:
          map['fruitRainEnabled'] ?? defaultFruitRainEnabled,
      growthNotifyEnabled:
          map['growthNotifyEnabled'] ?? defaultGrowthNotifyEnabled,
      lockscreenFirstEnabled:
          map['lockscreenFirstEnabled'] ?? defaultLockscreenFirstEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seedTime': seedTime,
      'notifyEnabled': notifyEnabled,
      'themeMode': themeMode,
      'fruitRainEnabled': fruitRainEnabled,
      'growthNotifyEnabled': growthNotifyEnabled,
      'lockscreenFirstEnabled': lockscreenFirstEnabled,
    };
  }

  AppSettings copyWith(
      {String? seedTime,
      bool? notifyEnabled,
      String? themeMode,
      bool? fruitRainEnabled,
      bool? growthNotifyEnabled,
      bool? lockscreenFirstEnabled}) {
    return AppSettings(
      seedTime: seedTime ?? this.seedTime,
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
      themeMode: themeMode ?? this.themeMode,
      fruitRainEnabled: fruitRainEnabled ?? this.fruitRainEnabled,
      growthNotifyEnabled: growthNotifyEnabled ?? this.growthNotifyEnabled,
      lockscreenFirstEnabled:
          lockscreenFirstEnabled ?? this.lockscreenFirstEnabled,
    );
  }
}
