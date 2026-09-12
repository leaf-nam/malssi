import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';
import 'package:malssi/features/archive/presentation/archive_screen.dart';
import 'package:malssi/features/archive/providers/archive_providers.dart';
import 'package:malssi/features/auth/presentation/login_screen.dart';
import 'package:malssi/features/landing/presentation/landing_screen.dart';
import 'package:malssi/features/onboarding/presentation/onboarding_screen.dart';
import 'package:malssi/features/onboarding/providers/onboarding_providers.dart';
import 'package:malssi/features/seed/presentation/seed_screen.dart';
import 'package:malssi/features/seed/providers/seed_providers.dart';
import 'package:malssi/features/settings/presentation/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  // 매 실행 랜딩을 짧게 보여준다 (#162).
  initialLocation: '/landing',
  routes: [
    // 3탭 셸 (#79). 하단 바 1개가 상주하고 내용만 교체되므로,
    // 탭 전환에 페이지 슬라이드가 없고 바 색상 블렌딩이 그대로 보인다.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShellView(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const SeedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/archive',
              builder: (context, state) => const ArchiveScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const LoginScreen(),
    ),
    // 첫 실행 도움말. 셸 밖에 두어 바 없이 전체 화면으로 보여준다 (#130).
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // 매 실행 짧게 보여주는 랜딩. 셸 밖 전체 화면이다 (#162).
    GoRoute(
      path: '/landing',
      builder: (context, state) => const LandingScreen(),
    ),
  ],
);

/// 3탭 셸 뷰. 바는 고정하고 `goBranch`로 내용만 교체한다.
///
/// 셸에서는 화면이 계속 살아있어 탭 진입 시 `initState`가 돌지 않으므로,
/// 탭 선택 시 명시적으로 새로고침한다 (#62 진입 갱신의 셸 버전).
/// 첫 실행(`autoShowOnFirstLaunch`, #130)에는 도움말(`/onboarding`)로
/// 1회 자동 이동한다. 셸이 앱 수명 동안 유지되므로 중복 이동은 없다.
class AppShellView extends StatefulWidget {
  const AppShellView({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShellView> createState() => _AppShellViewState();
}

class _AppShellViewState extends State<AppShellView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboarding();
    });
  }

  Future<void> _maybeShowOnboarding() async {
    if (!mounted) return;
    final onboarding = context.read<OnboardingProvider>();
    if (!onboarding.autoShowOnFirstLaunch) return;
    await onboarding.load();
    if (!mounted) return;
    if (onboarding.completed != true) {
      context.go('/onboarding');
    }
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(index);
    switch (index) {
      case 0:
        context.read<SeedProvider>().refreshGrowth();
      case 1:
        context.read<ArchiveProvider>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: MainBottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}
