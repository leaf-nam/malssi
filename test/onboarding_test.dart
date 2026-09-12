import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:malssi/app.dart';
import 'package:malssi/core/services/debug_clock.dart';
import 'package:malssi/features/onboarding/data/onboarding_repository.dart';
import 'package:malssi/features/onboarding/presentation/onboarding_screen.dart';
import 'package:malssi/features/onboarding/providers/onboarding_providers.dart';
import 'package:malssi/routing/app_router.dart';

Widget _wrap(OnboardingProvider provider, {VoidCallback? onFinished}) {
  return MultiProvider(
    providers: [ChangeNotifierProvider.value(value: provider)],
    child: MaterialApp(
      home: OnboardingScreen(onFinished: onFinished),
    ),
  );
}

void main() {
  // 마감 규칙(#147) 탓에 실제 시각에 의존하면 오후에 깨지므로,
  // 공용 시계를 오전으로 고정한다.
  setUp(() {
    DebugClock.shift(DateTime(2026, 9, 4, 8).difference(DateTime.now()));
  });
  tearDown(DebugClock.reset);
  group('PrefsOnboardingRepository (in-memory)', () {
    test('starts incomplete, completes, resets', () async {
      final repository = PrefsOnboardingRepository();

      expect(await repository.isCompleted(), isFalse);

      await repository.complete();
      expect(await repository.isCompleted(), isTrue);

      await repository.reset();
      expect(await repository.isCompleted(), isFalse);
    });

    test('respects initial completed value', () async {
      final repository = PrefsOnboardingRepository(completed: true);

      expect(await repository.isCompleted(), isTrue);
    });
  });

  group('PrefsOnboardingRepository (SharedPreferences)', () {
    test('persists completion flag', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = PrefsOnboardingRepository(prefs: prefs);

      expect(await repository.isCompleted(), isFalse);

      await repository.complete();
      expect(prefs.getBool(OnboardingRepository.completedKey), isTrue);

      // 새 인스턴스에서도 유지된다.
      final reopened = PrefsOnboardingRepository(prefs: prefs);
      expect(await reopened.isCompleted(), isTrue);

      await reopened.reset();
      expect(await repository.isCompleted(), isFalse);
    });
  });

  group('OnboardingProvider', () {
    test('load reflects repository, complete flips to true', () async {
      final provider = OnboardingProvider(
        repository: PrefsOnboardingRepository(completed: false),
      );

      expect(provider.completed, isNull);

      await provider.load();
      expect(provider.completed, isFalse);

      await provider.complete();
      expect(provider.completed, isTrue);
    });
  });

  group('OnboardingScreen', () {
    testWidgets('walks through all pages and finishes', (tester) async {
      var finished = false;
      final provider = OnboardingProvider(
        repository: PrefsOnboardingRepository(),
      );
      await provider.load();

      await tester.pumpWidget(
        _wrap(provider, onFinished: () => finished = true),
      );

      // 5개 페이지: 환영 → 말씨 → 정원 → 설정 → 시작.
      expect(find.text('말씨에 오신 것을 환영해요'), findsOneWidget);
      expect(find.text('건너뛰기'), findsOneWidget);
      expect(find.text('다음'), findsOneWidget);

      for (final title in [
        '말씨 탭 — 씨앗을 심어보세요',
        '정원 탭 — 모은 열매를 돌아보세요',
        '설정 탭 — 내 리듬에 맞추세요',
        '오늘의 씨앗을 만나보세요',
      ]) {
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
      }

      // 마지막 페이지에서는 시작하기만 보인다.
      expect(find.text('시작하기'), findsOneWidget);
      expect(find.text('건너뛰기'), findsNothing);

      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
      expect(provider.completed, isTrue);
    });

    testWidgets('shows screenshots on tab pages only', (tester) async {
      final provider = OnboardingProvider(
        repository: PrefsOnboardingRepository(),
      );
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      // 환영 페이지: 스크린샷 없이 아이콘만.
      expect(find.text('말씨에 오신 것을 환영해요'), findsOneWidget);
      expect(find.byType(Image), findsNothing);

      // 말씨 탭: 씨앗 잠금 → 성장 → 완성 열매 → 후기 5장.
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNWidgets(5));

      // 정원 탭: 잔디 그리드 1장.
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);

      // 설정 탭: 설정 + 시간 선택 2장.
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNWidgets(2));

      // 시작 페이지: 스크린샷 없이 아이콘만.
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('오늘의 씨앗을 만나보세요'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('titles stay on one line on narrow phones', (tester) async {
      // iPhone 16e 너비(390pt)에서도 제목이 두 줄로 끊기지 않아야 한다.
      // 넘침이 생기면 레이아웃 에러로 테스트가 실패한다.
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final provider = OnboardingProvider(
        repository: PrefsOnboardingRepository(),
      );
      await provider.load();

      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();

      for (var page = 0; page < onboardingPages.length; page++) {
        for (final title in onboardingPages.map((p) => p.title)) {
          final found = find.text(title).evaluate();
          if (found.isNotEmpty) {
            final text = found.single.widget as Text;
            expect(text.maxLines, 1, reason: title);
          }
        }
        expect(tester.takeException(), isNull);
        if (page < onboardingPages.length - 1) {
          await tester.tap(find.text('다음'));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('skip finishes immediately', (tester) async {
      var finished = false;
      final provider = OnboardingProvider(
        repository: PrefsOnboardingRepository(),
      );
      await provider.load();

      await tester.pumpWidget(
        _wrap(provider, onFinished: () => finished = true),
      );

      await tester.tap(find.text('건너뛰기'));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
      expect(provider.completed, isTrue);
    });
  });

  group('AppShell first-launch gate', () {
    // `appRouter`는 테스트 간에도 살아있는 싱글톤이라 이전 테스트의
    // 이동 위치(`/onboarding` 등)가 다음 테스트로 누수된다. 펌프 전에
    // 위치를 `/`로 되돌려 독립적으로 시작한다 (셸 게이트의 첫 프레임
    // 콜백이 펌프와 함께 실행되므로 리셋은 반드시 펌프 이전에 둔다).
    Future<void> pumpShell(WidgetTester tester, Widget shell) async {
      appRouter.go('/');
      await tester.pumpWidget(shell);
      await tester.pumpAndSettle();
    }

    testWidgets('does not auto-show without opt-in (default)',
        (tester) async {
      await pumpShell(tester, const AppShell());

      expect(find.text('씨앗 심기'), findsOneWidget);
      expect(find.text('말씨에 오신 것을 환영해요'), findsNothing);
    });

    testWidgets('auto-shows onboarding on first launch', (tester) async {
      appRouter.go('/');
      await tester.pumpWidget(
        AppShell(
          onboardingRepository: PrefsOnboardingRepository(completed: false),
          autoShowOnFirstLaunch: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('말씨에 오신 것을 환영해요'), findsOneWidget);
    });

    testWidgets('stays on tabs once completed', (tester) async {
      await pumpShell(
        tester,
        AppShell(
          onboardingRepository: PrefsOnboardingRepository(completed: true),
          autoShowOnFirstLaunch: true,
        ),
      );

      expect(find.text('씨앗 심기'), findsOneWidget);
      expect(find.text('말씨에 오신 것을 환영해요'), findsNothing);
    });

    testWidgets('settings has a rewatch entry', (tester) async {
      await pumpShell(tester, const AppShell());

      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();

      expect(find.text('도움말 다시 보기'), findsOneWidget);

      await tester.tap(find.text('도움말 다시 보기'));
      await tester.pumpAndSettle();

      expect(find.text('말씨에 오신 것을 환영해요'), findsOneWidget);
    });
  });
}
