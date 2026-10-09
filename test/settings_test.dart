import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:malssi/core/services/debug_ui.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/features/settings/data/settings_repository.dart';
import 'package:malssi/features/settings/domain/app_settings.dart';
import 'package:malssi/features/settings/presentation/settings_screen.dart';
import 'package:malssi/features/settings/providers/settings_providers.dart';

class _ScheduleCall {
  _ScheduleCall(this.hour, this.minute, this.enabled, this.lockscreenFirst);
  final int hour;
  final int minute;
  final bool enabled;
  final bool lockscreenFirst;
}

Widget _wrap(SettingsProvider provider, {DebugUiProvider? debugUi}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: provider),
      ChangeNotifierProvider.value(value: debugUi ?? DebugUiProvider()),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

void main() {
  group('AppSettings model', () {
    test('fromMap/toMap/copyWith round-trip', () {
      const settings = AppSettings(
          seedTime: '08:30',
          notifyEnabled: false,
          themeMode: 'dark',
          fruitRainEnabled: false,
          growthNotifyEnabled: true);
      final restored = AppSettings.fromMap(settings.toMap());

      expect(restored.seedTime, '08:30');
      expect(restored.notifyEnabled, isFalse);
      expect(restored.themeMode, 'dark');
      expect(restored.fruitRainEnabled, isFalse);
      expect(restored.growthNotifyEnabled, isTrue);
      // #253: 잠금 먼저 보기는 기본 off.
      expect(restored.lockscreenFirstEnabled, isFalse);
      expect(
          restored.copyWith(lockscreenFirstEnabled: true)
              .lockscreenFirstEnabled,
          isTrue);
      expect(restored.seedHour, 8);
      expect(restored.seedMinute, 30);
      expect(restored.copyWith(notifyEnabled: true).notifyEnabled, isTrue);
      expect(
          restored.copyWith(themeMode: 'light').themeMode, 'light');
      expect(restored.copyWith(fruitRainEnabled: true).fruitRainEnabled,
          isTrue);
      expect(
          restored.copyWith(growthNotifyEnabled: false).growthNotifyEnabled,
          isFalse);
    });

    test('fromMap defaults to 08:00 with notifications on and system theme',
        () {
      final settings = AppSettings.fromMap({});

      expect(settings.seedTime, AppSettings.defaultSeedTime);
      expect(settings.seedTime, '08:00');
      expect(settings.notifyEnabled, isTrue);
      expect(settings.themeMode, 'system');
      expect(settings.fruitRainEnabled, isTrue);
      // #244: 성장 알림은 기본값 on.
      expect(settings.growthNotifyEnabled, isTrue);
      // #253: 잠금 먼저 보기는 기본값 off (opt-in).
      expect(settings.lockscreenFirstEnabled, isFalse);
    });

    test('fromMap falls back to system theme on bad values', () {
      expect(AppSettings.fromMap({'themeMode': 'neon'}).themeMode,
          'system');
      expect(AppSettings.fromMap({}).themeMode, 'system');
    });

    test('isValidSeedTime accepts HH:mm only', () {
      expect(AppSettings.isValidSeedTime('12:00'), isTrue);
      expect(AppSettings.isValidSeedTime('00:00'), isTrue);
      expect(AppSettings.isValidSeedTime('23:59'), isTrue);
      expect(AppSettings.isValidSeedTime('24:00'), isFalse);
      expect(AppSettings.isValidSeedTime('9:00'), isFalse);
      expect(AppSettings.isValidSeedTime(''), isFalse);
    });

    test('isAllowedSeedTime blocks past the 14:00 deadline (#159)', () {
      expect(AppSettings.isAllowedSeedTime('08:00'), isTrue);
      expect(AppSettings.isAllowedSeedTime('13:59'), isTrue);
      expect(AppSettings.isAllowedSeedTime('14:00'), isTrue);
      expect(AppSettings.isAllowedSeedTime('14:01'), isFalse);
      expect(AppSettings.isAllowedSeedTime('23:59'), isFalse);
      expect(AppSettings.isAllowedSeedTime('9시'), isFalse);
      expect(AppSettings.isAllowedSeedTime(''), isFalse);
    });
  });

  group('InMemorySettingsRepository', () {
    test('starts with 08:00 defaults', () async {
      final repo = InMemorySettingsRepository();
      final settings = await repo.getSettings();

      expect(settings.seedTime, '08:00');
      expect(settings.notifyEnabled, isTrue);
      expect(settings.themeMode, 'system');
      expect(settings.fruitRainEnabled, isTrue);
    });

    test('updateSeedTime rejects bad format', () async {
      final repo = InMemorySettingsRepository();

      expect(() => repo.updateSeedTime('9시'), throwsArgumentError);
    });

    test('updateSeedTime rejects past the 14:00 deadline (#159)', () async {
      final repo = InMemorySettingsRepository();

      expect((await repo.updateSeedTime('14:00')).seedTime, '14:00');
      expect(() => repo.updateSeedTime('14:01'), throwsArgumentError);
      expect(() => repo.updateSeedTime('23:00'), throwsArgumentError);
      // 거부된 값은 저장되지 않는다.
      expect((await repo.getSettings()).seedTime, '14:00');
    });

    test('setThemeMode stores light/dark/system only', () async {
      final repo = InMemorySettingsRepository();

      expect((await repo.setThemeMode('dark')).themeMode, 'dark');
      expect(() => repo.setThemeMode('neon'), throwsArgumentError);
    });

    test('setFruitRainEnabled toggles the rain (#108)', () async {
      final repo = InMemorySettingsRepository();

      expect(
          (await repo.setFruitRainEnabled(false)).fruitRainEnabled,
          isFalse);
      expect(
          (await repo.setFruitRainEnabled(true)).fruitRainEnabled,
          isTrue);
    });

    test('setGrowthNotifyEnabled toggles growth alerts (#244)', () async {
      final repo = InMemorySettingsRepository();
      expect((await repo.getSettings()).growthNotifyEnabled, isTrue);

      expect(
          (await repo.setGrowthNotifyEnabled(false)).growthNotifyEnabled,
          isFalse);
      expect(
          (await repo.setGrowthNotifyEnabled(true)).growthNotifyEnabled,
          isTrue);
    });

    test('setLockscreenFirstEnabled toggles first-on-lock (#253)', () async {
      final repo = InMemorySettingsRepository();
      expect(
          (await repo.getSettings()).lockscreenFirstEnabled, isFalse);

      expect(
          (await repo.setLockscreenFirstEnabled(true))
              .lockscreenFirstEnabled,
          isTrue);
      expect(
          (await repo.setLockscreenFirstEnabled(false))
              .lockscreenFirstEnabled,
          isFalse);
    });
  });

  group('SettingsProvider', () {
    test('load reschedules with current settings', () async {
      final calls = <_ScheduleCall>[];
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
        onSettingsChanged: (
            {required hour,
            required minute,
            required enabled,
            required lockscreenFirst}) async {
          calls.add(
              _ScheduleCall(hour, minute, enabled, lockscreenFirst));
        },
      );

      await provider.load();

      expect(provider.settings!.seedTime, '08:00');
      expect(calls.length, 1);
      expect(calls.single.hour, 8);
      expect(calls.single.minute, 0);
      expect(calls.single.enabled, isTrue);
    });

    test('updateSeedTime and toggle reschedule', () async {      final calls = <_ScheduleCall>[];
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
        onSettingsChanged: (
            {required hour,
            required minute,
            required enabled,
            required lockscreenFirst}) async {
          calls.add(
              _ScheduleCall(hour, minute, enabled, lockscreenFirst));
        },
      );
      await provider.load();
      calls.clear();

      await provider.updateSeedTime('08:30');
      expect(provider.settings!.seedTime, '08:30');
      expect(calls.single.hour, 8);
      expect(calls.single.minute, 30);

      await provider.setNotifyEnabled(false);
      expect(provider.settings!.notifyEnabled, isFalse);
      expect(calls.last.enabled, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('updateSeedTime past the deadline keeps old value + error (#159)',
        () async {
      final calls = <_ScheduleCall>[];
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
        onSettingsChanged: (
            {required hour,
            required minute,
            required enabled,
            required lockscreenFirst}) async {
          calls.add(
              _ScheduleCall(hour, minute, enabled, lockscreenFirst));
        },
      );
      await provider.load();
      calls.clear();

      await provider.updateSeedTime('20:00');

      expect(provider.settings!.seedTime, '08:00');
      expect(provider.errorMessage, isNotNull);
      expect(calls, isEmpty);
    });

    test('setThemeMode stores the mode without rescheduling', () async {
      final calls = <_ScheduleCall>[];
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
        onSettingsChanged: (
            {required hour,
            required minute,
            required enabled,
            required lockscreenFirst}) async {
          calls.add(
              _ScheduleCall(hour, minute, enabled, lockscreenFirst));
        },
      );
      await provider.load();
      calls.clear();

      await provider.setThemeMode('dark');
      expect(provider.settings!.themeMode, 'dark');
      expect(calls, isEmpty);
      expect(provider.errorMessage, isNull);

      await provider.setThemeMode('neon');
      expect(provider.settings!.themeMode, 'dark');
      expect(provider.errorMessage, isNotNull);
    });

    test('setFruitRainEnabled toggles without rescheduling (#108)',
        () async {
      final calls = <_ScheduleCall>[];
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
        onSettingsChanged: (
            {required hour,
            required minute,
            required enabled,
            required lockscreenFirst}) async {
          calls.add(
              _ScheduleCall(hour, minute, enabled, lockscreenFirst));
        },
      );
      await provider.load();
      calls.clear();

      await provider.setFruitRainEnabled(false);
      expect(provider.settings!.fruitRainEnabled, isFalse);
      expect(calls, isEmpty);
      expect(provider.errorMessage, isNull);

      await provider.setFruitRainEnabled(true);
      expect(provider.settings!.fruitRainEnabled, isTrue);
      expect(calls, isEmpty);
      expect(provider.errorMessage, isNull);
    });

    test('setGrowthNotifyEnabled notifies the callback (#244)', () async {
      final growthCalls = <bool>[];
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
        onGrowthNotifyChanged: ({required enabled}) async {
          growthCalls.add(enabled);
        },
      );
      await provider.load();
      expect(provider.settings!.growthNotifyEnabled, isTrue);

      await provider.setGrowthNotifyEnabled(false);
      expect(provider.settings!.growthNotifyEnabled, isFalse);
      expect(growthCalls, [false]);
      expect(provider.errorMessage, isNull);

      await provider.setGrowthNotifyEnabled(true);
      expect(provider.settings!.growthNotifyEnabled, isTrue);
      expect(growthCalls, [false, true]);
      expect(provider.errorMessage, isNull);
    });

    test('setLockscreenFirstEnabled reschedules with the flag (#253)',
        () async {
      final calls = <_ScheduleCall>[];
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
        onSettingsChanged: (
            {required hour,
            required minute,
            required enabled,
            required lockscreenFirst}) async {
          calls.add(
              _ScheduleCall(hour, minute, enabled, lockscreenFirst));
        },
      );
      await provider.load();
      // 시작 상태: 매일 알림 on + 잠금 먼저 보기 off.
      expect(calls.single.enabled, isTrue);
      expect(calls.single.lockscreenFirst, isFalse);
      calls.clear();

      await provider.setLockscreenFirstEnabled(true);
      expect(provider.settings!.lockscreenFirstEnabled, isTrue);
      expect(calls.single.enabled, isTrue);
      expect(calls.single.lockscreenFirst, isTrue);
      expect(provider.errorMessage, isNull);

      await provider.setLockscreenFirstEnabled(false);
      expect(provider.settings!.lockscreenFirstEnabled, isFalse);
      expect(calls.last.lockscreenFirst, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('resyncLockscreen pushes current settings again (#253 후속)',
        () async {
      final calls = <_ScheduleCall>[];
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
        onSettingsChanged: (
            {required hour,
            required minute,
            required enabled,
            required lockscreenFirst}) async {
          calls.add(
              _ScheduleCall(hour, minute, enabled, lockscreenFirst));
        },
      );
      await provider.load();
      await provider.setLockscreenFirstEnabled(true);
      calls.clear();

      await provider.resyncLockscreen();

      expect(calls.single.enabled, isTrue);
      expect(calls.single.lockscreenFirst, isTrue);
      expect(provider.errorMessage, isNull);
    });
  });

  group('SettingsScreen', () {
    testWidgets('shows seed time, theme mode, and switches',
        (tester) async {
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
      );
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('씨앗 생성 시간'), findsOneWidget);
      expect(find.text('08:00 ›'), findsOneWidget);
      expect(find.text('화면 모드'), findsOneWidget);
      expect(find.text('다크'), findsOneWidget);
      expect(find.text('열매 비 효과'), findsOneWidget);
      expect(find.text('성장 알림'), findsOneWidget);
      // #253: 테스트 플랫폼은 Android라 잠금 먼저 보기 행이 보인다.
      expect(find.text('잠금화면에서 먼저 보기'), findsOneWidget);
      // 디버그 모드에서는 '디버그 버튼 숨기기' 스위치가 하나 더 보인다.
      expect(find.text('디버그 버튼 숨기기'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(5));
    });

    testWidgets('toggling the switch disables notifications', (tester) async {
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
      );
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).at(0));
      await tester.pumpAndSettle();

      expect(provider.settings!.notifyEnabled, isFalse);
    });

    testWidgets('mode buttons keep the same size in light and dark (#218)',
        (tester) async {
      Future<Size> sizeFor(ThemeData theme) async {
        final provider = SettingsProvider(
          settingsRepository: InMemorySettingsRepository(),
        );
        await provider.load();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: provider),
              ChangeNotifierProvider.value(value: DebugUiProvider()),
            ],
            child: MaterialApp(
                theme: theme, home: const SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();
        return tester
            .getSize(find.byType(SegmentedButton<String>));
      }

      final lightSize = await sizeFor(AppTheme.light());
      final darkSize = await sizeFor(AppTheme.dark());

      expect(darkSize, lightSize);
    });

    testWidgets('mode buttons keep size across selections (#218 후속)',
        (tester) async {
      // 선택된 세그먼트에만 체크 아이콘이 붙으면 선택 변경 시
      // 전체 너비가 흔들렸던 문제(270→234 실측) 회귀 방지.
      Future<Size> sizeForSelection(String mode) async {
        final provider = SettingsProvider(
          settingsRepository: InMemorySettingsRepository(),
        );
        await provider.load();
        await provider.setThemeMode(mode);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: provider),
              ChangeNotifierProvider.value(value: DebugUiProvider()),
            ],
            child: MaterialApp(
                theme: AppTheme.light(), home: const SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();
        return tester
            .getSize(find.byType(SegmentedButton<String>));
      }

      final lightSelected = await sizeForSelection('light');
      final darkSelected = await sizeForSelection('dark');
      final systemSelected = await sizeForSelection('system');

      expect(darkSelected, lightSelected);
      expect(systemSelected, lightSelected);
    });

    testWidgets('toggling the rain switch hides the rain (#108)',
        (tester) async {
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
      );
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      expect(provider.settings!.fruitRainEnabled, isTrue);

      await tester.tap(find.byType(Switch).at(2));
      await tester.pumpAndSettle();

      expect(provider.settings!.fruitRainEnabled, isFalse);
    });

    testWidgets('toggling the growth switch enables growth alerts (#244)',
        (tester) async {
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
      );
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      expect(provider.settings!.growthNotifyEnabled, isTrue);

      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();

      expect(provider.settings!.growthNotifyEnabled, isFalse);
    });

    testWidgets('toggling the lockscreen switch flips first-on-lock (#253)',
        (tester) async {
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
      );
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      expect(provider.settings!.lockscreenFirstEnabled, isFalse);

      await tester.tap(find.byType(Switch).at(3));
      await tester.pumpAndSettle();

      expect(provider.settings!.lockscreenFirstEnabled, isTrue);
    });
  });
}
