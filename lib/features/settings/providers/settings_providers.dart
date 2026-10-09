import 'package:flutter/foundation.dart';
import 'package:malssi/features/settings/data/settings_repository.dart';
import 'package:malssi/features/settings/domain/app_settings.dart';

/// 설정 변경 시 일일 알림을 다시 등록 + 잠금 오버레이를 동기화하는 콜백.
/// 실제 등록은 `app.dart`에서 `NotificationService`·`LockscreenService`로
/// 연결한다. 테스트에서는 기록용 가짜를 주입한다.
typedef RescheduleSeedNotification = Future<void> Function({
  required int hour,
  required int minute,
  required bool enabled,
  required bool lockscreenFirst,
});

/// 상단바 진행 알림 스위치 변경 시 호출된다 (#253 후속).
/// `enabled`가 false면 진행 중 알림을 즉시 종료하고,
/// true면 다음 스냅샷 갱신(탭 이동·15분·단계 변화) 때 다시 표시한다.
typedef ProgressNotifyChanged = Future<void> Function({
  required bool enabled,
});

/// 성장 알림 스위치 변경 시 호출된다 (#244).
/// `enabled`가 false면 예약 취소를, true면 남은 단계 예약을 요청한다.
/// 실제 예약·취소는 `app.dart`에서 `NotificationService`로 연결한다.
typedef GrowthNotifyChanged = Future<void> Function({
  required bool enabled,
});

/// 설정 탭 상태. `provider` + [ChangeNotifier] 패턴 (컨벤션 §3).
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required this._settingsRepository,
    this._onSettingsChanged,
    this._onGrowthNotifyChanged,
    this._onProgressNotifyChanged,
  });

  final SettingsRepository _settingsRepository;
  final RescheduleSeedNotification? _onSettingsChanged;
  final GrowthNotifyChanged? _onGrowthNotifyChanged;
  final ProgressNotifyChanged? _onProgressNotifyChanged;

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

  /// 열매 비 효과 on/off (#108). 알림 재등록과는 무관하다.
  Future<void> setFruitRainEnabled(bool enabled) async {
    _errorMessage = null;
    notifyListeners();
    try {
      _settings =
          await _settingsRepository.setFruitRainEnabled(enabled);
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      notifyListeners();
    }
  }

  /// 성장 단계 도달 알림 on/off (#244). 변경을 콜백으로 알린다.
  Future<void> setGrowthNotifyEnabled(bool enabled) async {
    _errorMessage = null;
    notifyListeners();
    try {
      _settings =
          await _settingsRepository.setGrowthNotifyEnabled(enabled);
      await _onGrowthNotifyChanged?.call(enabled: enabled);
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      notifyListeners();
    }
  }

  /// 잠금 해제 시 먼저 보기 on/off (#253, Android만).
  /// 일일 알림 재등록 경로(`_reschedule`)를 그대로 타서
  /// 씨앗 시각·매일 알림 변경과 같은 full-screen intent 플래그로 예약된다.
  Future<void> setLockscreenFirstEnabled(bool enabled) async {
    _errorMessage = null;
    notifyListeners();
    try {
      _settings =
          await _settingsRepository.setLockscreenFirstEnabled(enabled);
      await _reschedule();
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      notifyListeners();
    }
  }

  /// 잠금 오버레이 재동기화 (#253 후속).
  /// 시스템 설정에서 권한을 허용하고 앱으로 돌아오면 서비스가 안 돈 상태이므로
  /// 앱 복귀 시점에 현재 설정을 다시 푸시한다 (일일 알림 재예약 포함, 멱등).
  Future<void> resyncLockscreen() async {
    await _reschedule();
  }

  /// 상단바 진행 알림 on/off (#253 후속). 변경을 콜백으로 알린다.
  Future<void> setProgressNotifyEnabled(bool enabled) async {
    _errorMessage = null;
    notifyListeners();
    try {
      _settings =
          await _settingsRepository.setProgressNotifyEnabled(enabled);
      await _onProgressNotifyChanged?.call(enabled: enabled);
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
        lockscreenFirst: settings.lockscreenFirstEnabled,
      );
    } catch (e) {
      _errorMessage = '$e';
    }
  }
}
