import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:malssi/features/settings/data/settings_repository.dart';
import 'package:malssi/features/settings/domain/app_settings.dart';
import 'package:malssi/features/settings/presentation/settings_screen.dart';
import 'package:malssi/features/settings/providers/settings_providers.dart';

class _ScheduleCall {
  _ScheduleCall(this.hour, this.minute, this.enabled);
  final int hour;
  final int minute;
  final bool enabled;
}

Widget _wrap(SettingsProvider provider) {
  return MultiProvider(
    providers: [ChangeNotifierProvider.value(value: provider)],
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
          fruitRainEnabled: false);
      final restored = AppSettings.fromMap(settings.toMap());

      expect(restored.seedTime, '08:30');
      expect(restored.notifyEnabled, isFalse);
      expect(restored.themeMode, 'dark');
      expect(restored.fruitRainEnabled, isFalse);
      expect(restored.seedHour, 8);
      expect(restored.seedMinute, 30);
      expect(restored.copyWith(notifyEnabled: true).notifyEnabled, isTrue);
      expect(
          restored.copyWith(themeMode: 'light').themeMode, 'light');
      expect(restored.copyWith(fruitRainEnabled: true).fruitRainEnabled,
          isTrue);
    });

    test('fromMap defaults to 08:00 with notifications on and system theme',
        () {
      final settings = AppSettings.fromMap({});

      expect(settings.seedTime, AppSettings.defaultSeedTime);
      expect(settings.seedTime, '08:00');
      expect(settings.notifyEnabled, isTrue);
      expect(settings.themeMode, 'system');
      expect(settings.fruitRainEnabled, isTrue);
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
  });

  group('SettingsProvider', () {
    test('load reschedules with current settings', () async {
      final calls = <_ScheduleCall>[];
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
        onSettingsChanged:
            ({required hour, required minute, required enabled}) async {
          calls.add(_ScheduleCall(hour, minute, enabled));
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
        onSettingsChanged:
            ({required hour, required minute, required enabled}) async {
          calls.add(_ScheduleCall(hour, minute, enabled));
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

    test('setThemeMode stores the mode without rescheduling', () async {
      final calls = <_ScheduleCall>[];
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
        onSettingsChanged:
            ({required hour, required minute, required enabled}) async {
          calls.add(_ScheduleCall(hour, minute, enabled));
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
        onSettingsChanged:
            ({required hour, required minute, required enabled}) async {
          calls.add(_ScheduleCall(hour, minute, enabled));
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
      expect(find.byType(Switch), findsNWidgets(2));
      // #123: CC BY-SA 명언 출처 표시.
      expect(find.textContaining('위키인용집'), findsOneWidget);
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

    testWidgets('toggling the rain switch hides the rain (#108)',
        (tester) async {
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
      );
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      expect(provider.settings!.fruitRainEnabled, isTrue);

      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();

      expect(provider.settings!.fruitRainEnabled, isFalse);
    });
  });
}
