import 'package:flutter/foundation.dart';
import 'package:malssi/features/settings/data/settings_repository.dart';
import 'package:malssi/features/settings/domain/app_settings.dart';

/// 설정 변경 시 일일 알림을 다시 등록하는 콜백.
/// 실제 등록은 `app.dart`에서 `NotificationService`로 연결한다.
/// 테스트에서는 기록용 가짜를 주입한다.
typedef RescheduleSeedNotification = Future<void> Function({
  required int hour,
  required int minute,
  required bool enabled,
});

/// 설정 탭 상태. `provider` + [ChangeNotifier] 패턴 (컨벤션 §3).
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required this._settingsRepository,
    this._onSettingsChanged,
  });

  final SettingsRepository _settingsRepository;
  final RescheduleSeedNotification? _onSettingsChanged;

  AppSettings? _settings;
  AppSettings? get settings => _settings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _settings = await _settingsRepository.getSettings();
      await _reschedule();
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSeedTime(String seedTime) async {
    _errorMessage = null;
    notifyListeners();
    try {
      _settings = await _settingsRepository.updateSeedTime(seedTime);
      await _reschedule();
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> setNotifyEnabled(bool enabled) async {
    _errorMessage = null;
    notifyListeners();
    try {
      _settings = await _settingsRepository.setNotifyEnabled(enabled);
      await _reschedule();
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> setThemeMode(String themeMode) async {
    _errorMessage = null;
    notifyListeners();
    try {
      _settings = await _settingsRepository.setThemeMode(themeMode);
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> _reschedule() async {
    final settings = _settings;
    final reschedule = _onSettingsChanged;
    if (settings == null || reschedule == null) return;
    try {
      await reschedule(
        hour: settings.seedHour,
        minute: settings.seedMinute,
        enabled: settings.notifyEnabled,
      );
    } catch (e) {
      _errorMessage = '$e';
    }
  }
}
