import 'package:flutter/material.dart';
import 'package:malssi/app.dart';
import 'package:malssi/core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Notification init must never block app startup: on failure, log and continue.
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
  }
  runApp(const AppShell());
}
