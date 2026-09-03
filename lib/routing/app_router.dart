import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/quote_detail/presentation/comment_screen.dart';
import 'features/mypage/presentation/mypage_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/quote-detail/:quoteId',
      builder: (context, state) {
        final quoteId = state.pathParameters['quoteId'] ?? '';
        return CommentScreen();
      },
    ),
    GoRoute(
      path: '/mypage',
      builder: (context, state) => const MyPageScreen(),
    ),
  ],
);