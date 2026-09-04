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
      const settings =
          AppSettings(seedTime: '08:30', notifyEnabled: false);
      final restored = AppSettings.fromMap(settings.toMap());

      expect(restored.seedTime, '08:30');
      expect(restored.notifyEnabled, isFalse);
      expect(restored.seedHour, 8);
      expect(restored.seedMinute, 30);
      expect(restored.copyWith(notifyEnabled: true).notifyEnabled, isTrue);
    });

    test('fromMap defaults to noon with notifications on', () {
      final settings = AppSettings.fromMap({});

      expect(settings.seedTime, AppSettings.defaultSeedTime);
      expect(settings.notifyEnabled, isTrue);
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
    test('starts with noon defaults', () async {
      final repo = InMemorySettingsRepository();
      final settings = await repo.getSettings();

      expect(settings.seedTime, '12:00');
      expect(settings.notifyEnabled, isTrue);
    });

    test('updateSeedTime rejects bad format', () async {
      final repo = InMemorySettingsRepository();

      expect(() => repo.updateSeedTime('9시'), throwsArgumentError);
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

      expect(provider.settings!.seedTime, '12:00');
      expect(calls.length, 1);
      expect(calls.single.hour, 12);
      expect(calls.single.minute, 0);
      expect(calls.single.enabled, isTrue);
    });

    test('updateSeedTime and toggle reschedule', () async {
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

      await provider.updateSeedTime('08:30');
      expect(provider.settings!.seedTime, '08:30');
      expect(calls.single.hour, 8);
      expect(calls.single.minute, 30);

      await provider.setNotifyEnabled(false);
      expect(provider.settings!.notifyEnabled, isFalse);
      expect(calls.last.enabled, isFalse);
      expect(provider.errorMessage, isNull);
    });
  });

  group('SettingsScreen', () {
    testWidgets('shows seed time and notification switch', (tester) async {
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
      );
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      expect(find.text('설정'), findsWidgets);
      expect(find.text('씨앗 생성 시간'), findsOneWidget);
      expect(find.text('12:00 ›'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('toggling the switch disables notifications', (tester) async {
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
      );
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(provider.settings!.notifyEnabled, isFalse);
    });
  });
}
