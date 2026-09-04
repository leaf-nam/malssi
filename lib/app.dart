import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/services/notification_service.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/features/auth/data/dummy_auth_service.dart';
import 'package:malssi/features/category/data/hashtag_repository.dart';
import 'package:malssi/features/category/providers/category_providers.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/archive/providers/archive_providers.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/home/providers/home_providers.dart';
import 'package:malssi/features/my_quote/data/submission_repository.dart';
import 'package:malssi/features/my_quote/providers/write_providers.dart';
import 'package:malssi/features/mypage/data/user_repository.dart';
import 'package:malssi/features/mypage/providers/user_providers.dart';
import 'package:malssi/features/quote_detail/data/comment_repository.dart';
import 'package:malssi/features/quote_detail/providers/comment_providers.dart';
import 'package:malssi/features/seed/data/seed_repository.dart';
import 'package:malssi/features/seed/providers/seed_providers.dart';
import 'package:malssi/routing/app_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final quoteRepository = InMemoryQuoteRepository();
    final commentRepository = InMemoryCommentRepository();
    final seedRepository = InMemorySeedRepository();
    final fruitRepository = InMemoryFruitRepository();
    return MultiProvider(
      providers: [
        Provider<QuoteRepository>.value(value: quoteRepository),
        Provider<CommentRepository>.value(value: commentRepository),
        Provider<SeedRepository>.value(value: seedRepository),
        Provider<FruitRepository>.value(value: fruitRepository),
        ChangeNotifierProvider(
          create: (_) => SeedProvider(
            seedRepository: seedRepository,
            quoteRepository: quoteRepository,
            fruitRepository: fruitRepository,
          )..ensureTodaySeed(),
        ),
        ChangeNotifierProvider(
          create: (_) => ArchiveProvider(fruitRepository: fruitRepository)
            ..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => QuoteProvider(repository: quoteRepository)..fetchRandomQuote(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProfileProvider(repository: DummyUserRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => CommentProvider(repository: commentRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(repository: InMemoryHashtagRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => WriteProvider(repository: InMemorySubmissionRepository()),
        ),
        Provider(create: (_) => DummyAuthService()),
        Provider<NotificationService>(create: (_) => NotificationService.instance),
      ],
      child: MaterialApp.router(
        title: 'malssi',
        theme: AppTheme.dark(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        routerConfig: appRouter,
      ),
    );
  }
}
