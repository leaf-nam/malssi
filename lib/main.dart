import 'package:flutter/material.dart';
import 'package:malssi/app.dart';
import 'package:malssi/core/services/notification_service.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/home/data/quote_assets.dart';
import 'package:malssi/features/seed/data/seed_repository.dart';
import 'package:malssi/features/settings/data/settings_repository.dart';
import 'package:malssi/core/services/local_store.dart';
import 'package:malssi/features/onboarding/data/onboarding_repository.dart';
import 'package:malssi/routing/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Notification init must never block app startup: on failure, log and continue.
  try {
    // 알림 탭 → 말씨 탭(`/`)으로 이동한다 (#140).
    await NotificationService.instance.init(onTap: () => appRouter.go('/'));
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
  }
  // 번들 명언을 시작 전에 읽는다 (#123). 실패하면 기본 7시드로 동작.
  final quotes = await QuoteAssets.loadQuotes();
  // 로컬 저장소 연결 (#122). 실패하면 인메모리로 동작한다.
  LocalStore? store;
  try {
    store = await PrefsLocalStore.create();
  } catch (e) {
    debugPrint('LocalStore init failed: $e');
  }
  // 온보딩 완료 여부 (#130). 같은 SharedPreferences를 공유한다.
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('SharedPreferences init failed: $e');
  }
  final seedRepository = InMemorySeedRepository(store: store);
  final fruitRepository = InMemoryFruitRepository(store: store);
  final settingsRepository = InMemorySettingsRepository(store: store);
  for (final loader in [
    seedRepository.load,
    fruitRepository.load,
    settingsRepository.load,
  ]) {
    try {
      await loader();
    } catch (e) {
      debugPrint('Local restore failed: $e');
    }
  }
  runApp(AppShell(
    initialQuotes: quotes,
    seedRepository: seedRepository,
    fruitRepository: fruitRepository,
    settingsRepository: settingsRepository,
    onboardingRepository: PrefsOnboardingRepository(prefs: prefs),
    autoShowOnFirstLaunch: true,
  ));
}
