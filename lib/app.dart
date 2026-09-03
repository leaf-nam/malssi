import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/services/notification_service.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/features/auth/data/dummy_auth_service.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/home/providers/home_providers.dart';
import 'package:malssi/features/mypage/data/user_repository.dart';
import 'package:malssi/features/mypage/providers/user_providers.dart';
import 'package:malssi/routing/app_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => QuoteProvider(repository: InMemoryQuoteRepository())..fetchRandomQuote(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProfileProvider(repository: DummyUserRepository())..load(),
        ),
        Provider(create: (_) => DummyAuthService()),
        Provider<NotificationService>(create: (_) => NotificationService.instance),
      ],
      child: MaterialApp.router(
        title: 'malssi',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
      ),
    );
  }
}
