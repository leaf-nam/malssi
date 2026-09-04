import 'package:malssi/features/settings/domain/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();

  Stream<AppSettings> getSettingsStream();

  /// 씨앗 생성 시각 변경 (`'HH:mm'`). 형식이 틀리면 [ArgumentError].
  Future<AppSettings> updateSeedTime(String seedTime);

  Future<AppSettings> setNotifyEnabled(bool enabled);

  /// 화면 모드 변경 (`'light'`/`'dark'`/`'system'`). 형식이 틀리면 [ArgumentError].
  Future<AppSettings> setThemeMode(String themeMode);
}

/// Firestore 연동 전까지 사용하는 인메모리 구현. 영속성 없음.
class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({AppSettings? initial})
      : _settings = initial ??
            const AppSettings(
              seedTime: AppSettings.defaultSeedTime,
              notifyEnabled: true,
            );

  AppSettings _settings;

  @override
  Future<AppSettings> getSettings() async => _settings;

  @override
  Stream<AppSettings> getSettingsStream() => Stream.value(_settings);

  @override
  Future<AppSettings> updateSeedTime(String seedTime) async {
    if (!AppSettings.isValidSeedTime(seedTime)) {
      throw ArgumentError('Invalid seedTime (expected HH:mm): $seedTime');
    }
    _settings = _settings.copyWith(seedTime: seedTime);
    return _settings;
  }

  @override
  Future<AppSettings> setNotifyEnabled(bool enabled) async {
    _settings = _settings.copyWith(notifyEnabled: enabled);
    return _settings;
  }

  @override
  Future<AppSettings> setThemeMode(String themeMode) async {
    if (!AppSettings.isValidThemeMode(themeMode)) {
      throw ArgumentError('Invalid themeMode: $themeMode');
    }
    _settings = _settings.copyWith(themeMode: themeMode);
    return _settings;
  }
}
