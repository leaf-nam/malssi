import 'package:malssi/core/services/local_store.dart';
import 'package:malssi/features/settings/domain/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();

  Stream<AppSettings> getSettingsStream();

  /// 씨앗 생성 시각 변경 (`'HH:mm'`). 형식이 틀리면 [ArgumentError].
  Future<AppSettings> updateSeedTime(String seedTime);

  Future<AppSettings> setNotifyEnabled(bool enabled);

  /// 화면 모드 변경 (`'light'`/`'dark'`/`'system'`). 형식이 틀리면 [ArgumentError].
  Future<AppSettings> setThemeMode(String themeMode);

  /// 열매 비 효과 on/off (#108).
  Future<AppSettings> setFruitRainEnabled(bool enabled);
}

/// Firestore 연동 전까지 사용하는 인메모리 구현. 영속성 없음.
class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({AppSettings? initial, this._store})
      : _settings = initial ??
            const AppSettings(
              seedTime: AppSettings.defaultSeedTime,
              notifyEnabled: true,
            );

  AppSettings _settings;

  /// 로컬 저장소 (#122). `null`이면 순수 인메모리로 동작한다 (테스트 기본값).
  final LocalStore? _store;

  /// 저장된 설정을 불러온다. 저장소 미연결·빈 저장소에서는 기본값을 유지한다.
  /// `main()` 시작 시 1회 호출한다.
  Future<void> load() async {
    final store = _store;
    if (store == null) return;
    final raw = await store.readMap(StoreKeys.settings);
    if (raw.isEmpty) return;
    _settings = AppSettings.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<AppSettings> _save(AppSettings next) async {
    _settings = next;
    final store = _store;
    if (store != null) {
      await store.writeMap(StoreKeys.settings, next.toMap());
    }
    return _settings;
  }

  @override
  Future<AppSettings> getSettings() async => _settings;

  @override
  Stream<AppSettings> getSettingsStream() => Stream.value(_settings);

  @override
  Future<AppSettings> updateSeedTime(String seedTime) async {
    if (!AppSettings.isValidSeedTime(seedTime)) {
      throw ArgumentError('Invalid seedTime (expected HH:mm): $seedTime');
    }
    return _save(_settings.copyWith(seedTime: seedTime));
  }

  @override
  Future<AppSettings> setNotifyEnabled(bool enabled) async {
    return _save(_settings.copyWith(notifyEnabled: enabled));
  }

  @override
  Future<AppSettings> setThemeMode(String themeMode) async {
    if (!AppSettings.isValidThemeMode(themeMode)) {
      throw ArgumentError('Invalid themeMode: $themeMode');
    }
    return _save(_settings.copyWith(themeMode: themeMode));
  }

  @override
  Future<AppSettings> setFruitRainEnabled(bool enabled) async {
    return _save(_settings.copyWith(fruitRainEnabled: enabled));
  }
}
