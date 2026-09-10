import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/services/debug_ui.dart';
import 'package:malssi/core/services/notification_service.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/features/auth/data/dummy_auth_service.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/archive/providers/archive_providers.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/onboarding/data/onboarding_repository.dart';
import 'package:malssi/features/onboarding/providers/onboarding_providers.dart';
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
    this.onboardingRepository,
    this.autoShowOnFirstLaunch = false,
  });

  final List<Quote> initialQuotes;

  /// 외부 주입 저장소. `null`이면 인메모리 기본값으로 만든다.
  /// `main()`에서는 로컬 저장소 연결본을 넘긴다 (#122).
  final SeedRepository? seedRepository;
  final FruitRepository? fruitRepository;
  final SettingsRepository? settingsRepository;
  final QuoteRepository? quoteRepository;

  /// 온보딩 저장소 (#130). `null`이면 순수 인메모리로 동작한다.
  /// `main()`에서는 `SharedPreferences` 연결본을 넘긴다.
  final OnboardingRepository? onboardingRepository;

  /// `true`일 때만 첫 실행에 도움말로 자동 이동한다.
  /// `main()`에서만 `true`로 넘기고, 테스트 기본값은 `false`이다.
  final bool autoShowOnFirstLaunch;

  @override
  Widget build(BuildContext context) {
    final quoteRepository =
        this.quoteRepository ?? InMemoryQuoteRepository(seed: initialQuotes);
    final seedRepository =
        this.seedRepository ?? InMemorySeedRepository();
    final fruitRepository =
        this.fruitRepository ?? InMemoryFruitRepository();
    final onboardingRepository =
        this.onboardingRepository ?? PrefsOnboardingRepository();
    return MultiProvider(
      providers: [
        Provider<QuoteRepository>.value(value: quoteRepository),
        Provider<SeedRepository>.value(value: seedRepository),
        Provider<FruitRepository>.value(value: fruitRepository),
        ChangeNotifierProvider(
          create: (_) => OnboardingProvider(
            repository: onboardingRepository,
            autoShowOnFirstLaunch: autoShowOnFirstLaunch,
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SeedProvider(
            seedRepository: seedRepository,
            quoteRepository: quoteRepository,
            fruitRepository: fruitRepository,
            // #62: 앱 사용 중에도 15분마다 성장을 갱신한다.
            enableAutoRefresh: true,
            // #140: 완성 알림 예약·취소. 매일 알림 스위치가 꺼져 있으면 예약하지 않는다.
            onSeedPlanted: ({required completeAt}) async {
              final settings = await (settingsRepository ??
                      InMemorySettingsRepository())
                  .getSettings();
              if (!settings.notifyEnabled) return;
              await NotificationService.instance
                  .scheduleSeedCompleteNotification(
                id: NotificationService.seedCompleteNotificationId,
                title: '열매가 완성됐어요',
                body: '눌러서 오늘의 리뷰를 남겨보세요',
                completeAt: completeAt,
              );
              // 심었으므로 마감 리마인드는 취소한다 (#147).
              await NotificationService.instance.cancelSeedNotification(
                  NotificationService.seedReminderNotificationId);
            },
            onSeedCompleted: () async {
              await NotificationService.instance.cancelSeedNotification(
                  NotificationService.seedCompleteNotificationId);
              await NotificationService.instance.cancelSeedNotification(
                  NotificationService.seedReminderNotificationId);
            },
            // #147: 미심김 씨앗의 마감(14시) 1시간 전 리마인드. 당일 13:00 1회.
            onReminderDue: ({required reminderAt}) async {
              final settings = await (settingsRepository ??
                      InMemorySettingsRepository())
                  .getSettings();
              if (!settings.notifyEnabled) return;
              await NotificationService.instance
                  .scheduleSeedCompleteNotification(
                id: NotificationService.seedReminderNotificationId,
                title: '오늘의 씨앗이 곧 마감돼요',
                body: '14시 전에 씨앗을 심어보세요',
                completeAt: reminderAt,
              );
            },
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
                // 매일 알림을 끄면 완성·리마인드 알림도 함께 취소한다 (#140, #147).
                await NotificationService.instance.cancelSeedNotification(
                    NotificationService.seedNotificationId);
                await NotificationService.instance.cancelSeedNotification(
                    NotificationService.seedCompleteNotificationId);
                await NotificationService.instance.cancelSeedNotification(
                    NotificationService.seedReminderNotificationId);
              }
            },
          )..load(),
        ),
        Provider(create: (_) => DummyAuthService()),
        ChangeNotifierProvider(create: (_) => DebugUiProvider()),
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
            // 스크린샷에 디버그 리본이 찍히지 않게 항상 가린다.
            debugShowCheckedModeBanner: false,
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
