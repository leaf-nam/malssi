class AppSettings {
  final String seedTime;
  final bool notifyEnabled;

  const AppSettings({
    required this.seedTime,
    required this.notifyEnabled,
  });

  static const defaultSeedTime = '12:00';

  static final RegExp _timePattern =
      RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  /// `'HH:mm'` 형식 검증.
  static bool isValidSeedTime(String value) =>
      _timePattern.hasMatch(value);

  int get seedHour => int.parse(seedTime.split(':')[0]);
  int get seedMinute => int.parse(seedTime.split(':')[1]);

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      seedTime: map['seedTime'] ?? defaultSeedTime,
      notifyEnabled: map['notifyEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seedTime': seedTime,
      'notifyEnabled': notifyEnabled,
    };
  }

  AppSettings copyWith({String? seedTime, bool? notifyEnabled}) {
    return AppSettings(
      seedTime: seedTime ?? this.seedTime,
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
    );
  }
}
