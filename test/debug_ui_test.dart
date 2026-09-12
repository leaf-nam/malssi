import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:malssi/core/services/debug_clock.dart';
import 'package:malssi/core/services/debug_ui.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/seed/data/seed_repository.dart';
import 'package:malssi/features/seed/presentation/seed_screen.dart';
import 'package:malssi/features/seed/providers/seed_providers.dart';
import 'package:malssi/features/settings/data/settings_repository.dart';
import 'package:malssi/features/settings/presentation/settings_screen.dart';
import 'package:malssi/features/settings/providers/settings_providers.dart';

Widget _wrapSeed(SeedProvider provider, DebugUiProvider debugUi) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: provider),
      ChangeNotifierProvider.value(value: debugUi),
    ],
    child: const MaterialApp(home: SeedScreen()),
  );
}

Widget _wrapSettings(SettingsProvider provider, DebugUiProvider debugUi) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: provider),
      ChangeNotifierProvider.value(value: debugUi),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

void main() {
  // 마감 규칙(#147) 탓에 실제 시각에 의존하면 오후에 깨지므로,
  // 공용 시계를 오전으로 고정한다.
  setUp(() {
    DebugClock.shift(DateTime(2026, 9, 4, 8).difference(DateTime.now()));
  });
  tearDown(DebugClock.reset);
  group('DebugUiProvider', () {
    test('shows buttons by default in debug mode', () {
      final debugUi = DebugUiProvider();

      expect(debugUi.hideButtons, isFalse);
      // 위젯 테스트는 디버그 모드이므로 실행 옵션이 없으면 보인다.
      expect(debugUi.showButtons, kDebugMode && !DebugUi.hideButtons);
    });

    test('setHideButtons hides and restores', () {
      final debugUi = DebugUiProvider();

      debugUi.setHideButtons(true);
      expect(debugUi.hideButtons, isTrue);
      expect(debugUi.showButtons, isFalse);

      debugUi.setHideButtons(false);
      expect(debugUi.hideButtons, isFalse);
    });
  });

  group('SeedScreen debug toggle', () {
    testWidgets('hides debug buttons when the switch is on',
        (tester) async {
      final provider = SeedProvider(
        seedRepository: InMemorySeedRepository(),
        quoteRepository: InMemoryQuoteRepository(),
        fruitRepository: InMemoryFruitRepository(),
      );
      await provider.ensureTodaySeed();
      final debugUi = DebugUiProvider()..setHideButtons(true);

      await tester.pumpWidget(_wrapSeed(provider, debugUi));
      await tester.pumpAndSettle();

      expect(find.text('씨앗 심기'), findsOneWidget);
      expect(find.text('디버그: +1시간'), findsNothing);
      expect(find.text('디버그: +1일'), findsNothing);
    });

    testWidgets('shows debug buttons when the switch is off',
        (tester) async {
      final provider = SeedProvider(
        seedRepository: InMemorySeedRepository(),
        quoteRepository: InMemoryQuoteRepository(),
        fruitRepository: InMemoryFruitRepository(),
      );
      await provider.ensureTodaySeed();

      await tester.pumpWidget(_wrapSeed(provider, DebugUiProvider()));
      await tester.pumpAndSettle();

      expect(find.text('디버그: +1시간'), findsOneWidget);
      expect(find.text('디버그: +1일'), findsOneWidget);
    });
  });

  group('SettingsScreen debug toggle', () {
    testWidgets('shows the hide switch in debug mode and flips the provider',
        (tester) async {
      final provider = SettingsProvider(
        settingsRepository: InMemorySettingsRepository(),
      );
      await provider.load();
      final debugUi = DebugUiProvider();

      await tester.pumpWidget(_wrapSettings(provider, debugUi));
      await tester.pumpAndSettle();

      // 디버그 모드에서만 보이는 스위치.
      expect(find.text('디버그 버튼 숨기기'), findsOneWidget);
      expect(debugUi.hideButtons, isFalse);

      await tester.tap(find.byType(Switch).last);
      await tester.pumpAndSettle();

      expect(debugUi.hideButtons, isTrue);
    });
  });
}
