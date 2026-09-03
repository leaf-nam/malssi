import 'package:flutter/material.dart';
import 'package:malssi/app.dart';
import 'package:malssi/core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const AppShell());
}
