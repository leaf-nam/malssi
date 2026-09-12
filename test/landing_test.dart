import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:malssi/app.dart';
import 'package:malssi/features/landing/presentation/landing_screen.dart';
import 'package:malssi/features/onboarding/data/onboarding_repository.dart';
import 'package:malssi/routing/app_router.dart';

void main() {
  group('LandingScreen', () {
    testWidgets('shows the brand', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LandingScreen(onDone: _noop),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('말씨'), findsOneWidget);
      expect(find.text('오늘의 명언을 심어보세요'), findsOneWidget);
    });

    testWidgets('auto-advances after the display duration',
        (tester) async {
      var done = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LandingScreen(
            displayDuration: const Duration(milliseconds: 100),
            onDone: () => done = true,
          ),
        ),
      );
      expect(done, isFalse);

      await tester.pump(const Duration(milliseconds: 100));

      expect(done, isTrue);
    });

    testWidgets('tap skips immediately', (tester) async {
      var done = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LandingScreen(onDone: () => done = true),
        ),
      );

      await tester.tap(find.text('말씨'));
      await tester.pump();

      expect(done, isTrue);
    });
  });

  group('Landing routing (#162)', () {
    testWidgets('first launch goes to onboarding', (tester) async {
      appRouter.go('/landing');
      await tester.pumpWidget(
        AppShell(
          onboardingRepository: PrefsOnboardingRepository(completed: false),
          autoShowOnFirstLaunch: true,
        ),
      );
      // 랜딩 자동 이동(1.5s) 타이머를 명시적으로 발화시킨다.
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(find.text('말씨에 오신 것을 환영해요'), findsOneWidget);
    });

    testWidgets('returning launch goes to the seed tab', (tester) async {
      appRouter.go('/landing');
      await tester.pumpWidget(
        AppShell(
          onboardingRepository: PrefsOnboardingRepository(completed: true),
          autoShowOnFirstLaunch: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(find.text('씨앗 심기'), findsOneWidget);
    });
  });
}

void _noop() {}
