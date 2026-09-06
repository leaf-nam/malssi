import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/services/notification_service.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/features/auth/data/dummy_auth_service.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/archive/providers/archive_providers.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/data/seed_repository.dart';
import 'package:malssi/features/seed/providers/seed_providers.dart';
import 'package:malssi/features/settings/data/settings_repository.dart';
import 'package:malssi/features/settings/providers/settings_providers.dart';
import 'package:malssi/routing/app_router.dart';

class AppShell extends StatelessWidget {
  /// 번들 명언 에셋 로드분. 비어 있으면 저장소가 기본 7시드로 동작한다 (#123).
  const AppShell({
    super.key,
    this.initialQuotes = const [],
    this.seedRepository,
    this.fruitRepository,
    this.settingsRepository,
    this.quoteRepository,
  });

  final List<Quote> initialQuotes;

  /// 외부 주입 저장소. `null`이면 인메모리 기본값으로 만든다.
  /// `main()`에서는 로컬 저장소 연결본을 넘긴다 (#122).
  final SeedRepository? seedRepository;
  final FruitRepository? fruitRepository;
  final SettingsRepository? settingsRepository;
  final QuoteRepository? quoteRepository;

  @override
  Widget build(BuildContext context) {
    final quoteRepository =
        this.quoteRepository ?? InMemoryQuoteRepository(seed: initialQuotes);
    final seedRepository =
        this.seedRepository ?? InMemorySeedRepository();
    final fruitRepository =
        this.fruitRepository ?? InMemoryFruitRepository();
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
            // #62: 앱 사용 중에도 15분마다 성장을 갱신한다.
            enableAutoRefresh: true,
          )..ensureTodaySeed(),
        ),
        ChangeNotifierProvider(
          create: (_) => ArchiveProvider(fruitRepository: fruitRepository)
            ..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            settingsRepository:
                settingsRepository ?? InMemorySettingsRepository(),
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
