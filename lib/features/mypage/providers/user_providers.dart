import 'package:flutter/material.dart';
import 'package:malssi/features/mypage/data/user_repository.dart';

/// Minimal [ChangeNotifier]-based state for the my-page screen.
class UserProfileProvider extends ChangeNotifier {
  UserProfileProvider({required this._repository});

  final UserRepository _repository;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _dailyNotification = true;
  bool get dailyNotification => _dailyNotification;

  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay get notificationTime => _notificationTime;

  String get notificationTimeLabel {
    final period = _notificationTime.period == DayPeriod.am ? '오전' : '오후';
    final hour = _notificationTime.hourOfPeriod == 0 ? 12 : _notificationTime.hourOfPeriod;
    final minute = _notificationTime.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _profile = await _repository.getUserProfile();
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setDailyNotification(bool value) {
    _dailyNotification = value;
    notifyListeners();
  }

  void setNotificationTime(TimeOfDay value) {
    _notificationTime = value;
    notifyListeners();
  }
}
