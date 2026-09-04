import 'package:go_router/go_router.dart';
import 'package:malssi/features/archive/presentation/archive_screen.dart';
import 'package:malssi/features/auth/presentation/login_screen.dart';
import 'package:malssi/features/seed/presentation/seed_screen.dart';
import 'package:malssi/features/settings/presentation/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SeedScreen(),
    ),
    GoRoute(
      path: '/archive',
      builder: (context, state) => const ArchiveScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);
