import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/services/debug_ui.dart';
import 'package:malssi/core/services/home_widget_service.dart';
import 'package:malssi/core/services/live_activity_service.dart';
import 'package:malssi/core/services/lockscreen_service.dart';
import 'package:malssi/core/services/notification_service.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/widgets/update_gate.dart';
import 'package:malssi/features/auth/data/dummy_auth_service.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/archive/providers/archive_providers.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/onboarding/data/onboarding_repository.dart';
import 'package:malssi/features/onboarding/providers/onboarding_providers.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/domain/seed.dart';
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
    this.updateCheckEnabled = true,
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

  /// 스토어 업데이트 확인 여부 (#192). 테스트에서는 `false`로 둔다
  /// (스토어 조회 네트워크 방지). `main()` 기본값은 `true`이다.
  final bool updateCheckEnabled;

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
          create: (_) {
            final seedProvider = SeedProvider(
              seedRepository: seedRepository,
              quoteRepository: quoteRepository,
              fruitRepository: fruitRepository,
              // #62: 앱 사용 중에도 15분마다 성장을 갱신한다.
              enableAutoRefresh: true,
            // #196: 배달 시각을 설정 저장소에서 읽는다.
            seedTimeLoader: () async =>
                (await (settingsRepository ??
                        InMemorySettingsRepository())
                    .getSettings())
                    .seedTime,
            // #140: 완성 알림 예약·취소. 매일 알림 스위치가 꺼져 있으면 예약하지 않는다.
            onSeedPlanted: ({required completeAt}) async {
              final settings = await (settingsRepository ??
                      InMemorySettingsRepository())
                  .getSettings();
              if (settings.notifyEnabled) {
                final seed = await seedRepository.getActiveSeed();
                await _scheduleGrowingSeedAlerts(
                  seed,
                  growthEnabled: settings.growthNotifyEnabled,
                );
              }
              // 심었으므로 마감 리마인드는 취소한다 (#147).
              await NotificationService.instance.cancelSeedNotification(
                  NotificationService.seedReminderNotificationId);
              // #244: 디버그에서 예약 목록을 로그로 확인한다 (ID 1002·2001~2004).
              // 스위치가 꺼져 있어도 찍는다 (예약 안 된 원인을 구분하기 위해).
              if (kDebugMode) {
                final pending = await NotificationService.instance
                    .pendingIds();
                debugPrint('pending notifications: $pending');
              }
            },
            onSeedCompleted: () async {
              await NotificationService.instance.cancelSeedNotification(
                  NotificationService.seedCompleteNotificationId);
              await NotificationService.instance.cancelSeedNotification(
                  NotificationService.seedReminderNotificationId);
              // #244: 완성됐으므로 남은 성장 알림도 취소한다.
              for (var stage = 1;
                  stage < Seed.maxGrowthStage;
                  stage++) {
                await NotificationService.instance.cancelSeedNotification(
                    NotificationService.growthNotificationId(stage));
              }
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
            )..ensureTodaySeed();
            // #139: 공개된 명언을 홈 위젯에 반영한다.
            // #242: 성장 상태(단계·다음 단계·완성 시각)도 함께 전달한다.
            // #248: Live Activity(잠금화면 실시간 카운트다운)도 함께 동기화한다.
            // 중복 갱신은 서비스가 제거하고, 실패해도 앱에 영향없다.
            // #253 후속: 전역 알림 off면 진행 중 알림(Live Activity)도
            // 종료한다 (Android 진행 중 알림 포함 — 홈 위젯은 알림이 아니라 유지).
            seedProvider.addListener(() {
              unawaited(_syncSeedSnapshot(
                seedProvider,
                settingsRepository,
              ));
            });
            return seedProvider;
          },
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
                ({required hour, required minute, required enabled, required bool lockscreenFirst}) async {
              if (enabled) {
                // #244 후속: OS 권한이 거부된 상태에서는 예약을 해도
                // 알림이 오지 않으므로, 켜는 시점에 권한을 먼저 요청한다.
                // 거부돼도 예약은 진행한다 (시스템 설정에서 허용하면 동작).
                await NotificationService.instance.requestPermissions();
                await NotificationService.instance
                    .scheduleDailySeedNotification(
                  id: NotificationService.seedNotificationId,
                  title: '오늘의 씨앗이 도착했어요',
                  body: '씨앗을 깨고 오늘의 명언을 만나보세요',
                  hour: hour,
                  minute: minute,
                );
                // 꺼져 있을 때 심은 씨앗은 완성·성장 예약이 안 되어 있으므로,
                // 켜는 시점에 성장 중 씨앗이 있으면 (재)예약한다.
                final settings = await (settingsRepository ??
                        InMemorySettingsRepository())
                    .getSettings();
                final seed = await seedRepository.getActiveSeed();
                if (seed.isGrowing) {
                  await _scheduleGrowingSeedAlerts(
                    seed,
                    growthEnabled: settings.growthNotifyEnabled,
                  );
                }
              } else {
                // 매일 알림을 끄면 완성·리마인드·성장 알림도 함께 취소한다
                // (#140, #147, #244).
                await NotificationService.instance.cancelSeedNotification(
                    NotificationService.seedNotificationId);
                await NotificationService.instance.cancelSeedNotification(
                    NotificationService.seedCompleteNotificationId);
                await NotificationService.instance.cancelSeedNotification(
                    NotificationService.seedReminderNotificationId);
                for (var stage = 1;
                    stage < Seed.maxGrowthStage;
                    stage++) {
                  await NotificationService.instance.cancelSeedNotification(
                      NotificationService.growthNotificationId(stage));
                }
                // #253 후속: 진행 중 알림도 즉시 종료한다.
                // 스냅샷 게이트만으로는 다음 갱신까지 남아 있게 된다.
                await LiveActivityService.instance.endAll();
              }
              // #253: 잠금 오버레이 상태를 설정과 일치시킨다.
              // 전역 알림 마스터가 꺼져 있으면 오버레이도 중단한다
              // (#253 후속 — '알림' off면 씨앗·완성·리마인드·성장 + 오버레이 전부 off).
              // iOS·권한 미허용에서는 네이티브가 무시한다.
              final lockscreenOn = lockscreenFirst && enabled;
              if (kDebugMode) {
                debugPrint(
                    'lockscreen sync: lockscreenFirst=$lockscreenFirst '
                    'enabled=$enabled');
              }
              final lockscreenOk = await LockscreenService.instance
                  .setEnabled(lockscreenOn);
              if (kDebugMode) {
                debugPrint('lockscreen sync result: $lockscreenOk');
              }
            },
            // #244: 성장 알림 스위치 변경. 끄면 예약을 취소하고,
            // 켜면 성장 중 씨앗의 남은 단계 알림을 예약한다.
            onGrowthNotifyChanged: ({required enabled}) async {
              if (!enabled) {
                for (var stage = 1;
                    stage < Seed.maxGrowthStage;
                    stage++) {
                  await NotificationService.instance.cancelSeedNotification(
                      NotificationService.growthNotificationId(stage));
                }
                return;
              }
              final settings = await (settingsRepository ??
                      InMemorySettingsRepository())
                  .getSettings();
              if (!settings.notifyEnabled) return;
              final seed = await seedRepository.getActiveSeed();
              await _scheduleGrowingSeedAlerts(seed, growthEnabled: true);
            },
            // #253 후속: 상단바 진행 알림 스위치 변경. 끄면 진행 중 알림을
            // 즉시 종료하고, 켜면 다음 스냅샷 갱신 때 다시 표시한다.
            onProgressNotifyChanged: ({required enabled}) async {
              if (enabled) return;
              await LiveActivityService.instance.endAll();
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
            // #192: 전 화면에서 스토어 업데이트를 확인한다 (랜딩 포함).
            // #201: 시스템 글씨 크기를 고정 레이아웃이 깨지지 않는 범위로
            // 고정한다. Android는 시스템 글씨 크기가 textScaler로 그대로
            // 들어오고(iOS는 1.0 유지), 상한이 없으면 고정 박스가 잘린다.
            builder: (context, child) =>
                MediaQuery.withClampedTextScaling(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.2,
              child: UpdateGate(
                enabled: updateCheckEnabled,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 씨앗 스냅샷을 위젯·Live Activity에 반영한다 (리스너 본문, #139·#242·#248).
/// 전역 알림 off면 진행 중 알림을 종료한다 (#253 후속).
/// 홈 위젯은 알림이 아니라 유지하고, 오버레이 중단은 `onSettingsChanged`가 담당.
Future<void> _syncSeedSnapshot(
  SeedProvider seedProvider,
  SettingsRepository? settingsRepository,
) async {
  final quote = seedProvider.revealedQuote;
  final seed = seedProvider.todaySeed;
  if (quote == null || seed == null) {
    HomeWidgetService.instance.updatePlaceholder();
    LiveActivityService.instance.syncSeed(
      dateKey: '',
      quoteText: '',
      status: 'locked',
      stage: 0,
    );
    return;
  }
  final settings = await (settingsRepository ?? InMemorySettingsRepository())
      .getSettings();
  final now = DateTime.now();
  final growing = seed.isGrowing;
  final completeAtIso = growing
      ? seed.plantedAt
          .add(Seed.stageInterval * Seed.maxGrowthStage)
          .toUtc()
          .toIso8601String()
      : '';
  HomeWidgetService.instance.updateSeed(
    quoteId: quote.id,
    text: quote.text,
    author: quote.author,
    status: seed.status,
    stage: seed.growthStageAt(now),
    totalStages: Seed.totalStages,
    seedDate: seed.dateKey,
    theme: seed.theme,
    nextStageAtIso: growing
        ? now
            .add(seed.timeUntilNextStage(now))
            // 네이티브 공용 형식: UTC ISO8601 (#242).
            .toUtc()
            .toIso8601String()
        : '',
    completeAtIso: completeAtIso,
  );
  if (settings.notifyEnabled) {
    LiveActivityService.instance.syncSeed(
      dateKey: seed.dateKey,
      quoteText: quote.text,
      status: seed.status,
      stage: seed.growthStageAt(now),
      completeAtIso: completeAtIso,
    );
  } else {
    await LiveActivityService.instance.endAll();
  }
}

/// 성장 중 씨앗의 완성·성장 알림을 (재)예약한다 (#244 후속).
/// 심기·매일 알림 on·성장 알림 on 시점에 호출한다.
/// [growthEnabled]가 false면 완성 알림만 예약한다.
/// 5단계 도달은 완성 알림이 담당하고, 이미 지난 시각은 건너뛴다
/// (`scheduleSeedCompleteNotification`이 무시).
/// 디버그 시간 이동으로 가짜 시각에 심은 씨앗은 실제 시각과 어긋나
/// 예약이 건너뛰어질 수 있다 (OS는 실제 시각 기준이라 정상).
Future<void> _scheduleGrowingSeedAlerts(
  Seed seed, {
  required bool growthEnabled,
}) async {
  if (kDebugMode) {
    debugPrint('schedule growing alerts: seed=${seed.id} '
        'status=${seed.status} plantedAt=${seed.plantedAt} '
        'growth=$growthEnabled');
  }
  final completeAt =
      seed.plantedAt.add(Seed.stageInterval * Seed.maxGrowthStage);
  await NotificationService.instance.scheduleSeedCompleteNotification(
    id: NotificationService.seedCompleteNotificationId,
    title: '열매가 완성됐어요',
    body: '눌러서 오늘의 리뷰를 남겨보세요',
    completeAt: completeAt,
  );
  if (!growthEnabled) return;
  for (final item in seed.pendingGrowthStages(DateTime.now())) {
    await NotificationService.instance.scheduleSeedCompleteNotification(
      id: NotificationService.growthNotificationId(item.stage),
      title: '씨앗이 자랐어요',
      body: '${item.stage}단계가 됐어요',
      completeAt: item.at,
    );
  }
}
