import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';
import 'package:malssi/features/archive/presentation/archive_screen.dart';
import 'package:malssi/features/archive/providers/archive_providers.dart';
import 'package:malssi/features/auth/presentation/login_screen.dart';
import 'package:malssi/features/seed/presentation/seed_screen.dart';
import 'package:malssi/features/seed/providers/seed_providers.dart';
import 'package:malssi/features/settings/presentation/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
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
  ],
);

/// 3탭 셸 뷰. 바는 고정하고 `goBranch`로 내용만 교체한다.
///
/// 셸에서는 화면이 계속 살아있어 탭 진입 시 `initState`가 돌지 않으므로,
/// 탭 선택 시 명시적으로 새로고침한다 (#62 진입 갱신의 셸 버전).
class AppShellView extends StatelessWidget {
  const AppShellView({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(index);
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
      body: navigationShell,
      bottomNavigationBar: MainBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}
