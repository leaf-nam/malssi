import 'package:flutter/material.dart';
import 'package:malssi/app.dart';
import 'package:malssi/core/services/notification_service.dart';
import 'package:malssi/features/home/data/quote_assets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Notification init must never block app startup: on failure, log and continue.
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
  }
  // 번들 명언 719件을 시작 전에 읽는다 (#123). 실패하면 기본 7시드로 동작.
  final quotes = await QuoteAssets.loadQuotes();
  runApp(AppShell(initialQuotes: quotes));
}
