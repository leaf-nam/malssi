import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/services/notification_service.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/features/auth/data/dummy_auth_service.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/archive/providers/archive_providers.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/seed/data/seed_repository.dart';
import 'package:malssi/features/seed/providers/seed_providers.dart';
import 'package:malssi/features/settings/data/settings_repository.dart';
import 'package:malssi/features/settings/providers/settings_providers.dart';
import 'package:malssi/routing/app_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final quoteRepository = InMemoryQuoteRepository();
    final seedRepository = InMemorySeedRepository();
    final fruitRepository = InMemoryFruitRepository();
    return MultiProvider(
      providers: [
        Provider<QuoteRepository>.value(value: quoteRepository),
        Provider<SeedRepository>.value(value: seedRepository),
        Provider<FruitRepository>.value(value: fruitRepository),
        ChangeNotifierProvider(
          create: (_) => SeedProvider(
            seedRepository: seedRepository,
            quoteRepository: quoteRepository,
            fruitRepository: fruitRepository,
          )..ensureTodaySeed(),
        ),
        ChangeNotifierProvider(
          create: (_) => ArchiveProvider(fruitRepository: fruitRepository)
            ..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            settingsRepository: InMemorySettingsRepository(),
            onSettingsChanged:
                ({required hour, required minute, required enabled}) async {
              if (enabled) {
                await NotificationService.instance
                    .scheduleDailySeedNotification(
                  id: NotificationService.seedNotificationId,
                  title: '오늘의 씨앗이 도착했어요',
                  body: '씨앗을 깨고 오늘의 명언을 만나보세요',
                  hour: hour,
                  minute: minute,
                );
              } else {
                await NotificationService.instance.cancelSeedNotification(
                    NotificationService.seedNotificationId);
              }
            },
          )..load(),
        ),
        Provider(create: (_) => DummyAuthService()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (_, settingsState, __) {
          final themeMode = switch (settingsState.settings?.themeMode) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          };
          return MaterialApp.router(
            title: 'malssi',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
