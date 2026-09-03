import 'package:go_router/go_router.dart';
import 'package:malssi/features/auth/presentation/login_screen.dart';
import 'package:malssi/features/home/presentation/home_screen.dart';
import 'package:malssi/features/mypage/presentation/mypage_screen.dart';
import 'package:malssi/features/quote_detail/presentation/comment_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/home',
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
        return CommentScreen(quoteId: quoteId);
      },
    ),
    GoRoute(
      path: '/mypage',
      builder: (context, state) => const MyPageScreen(),
    ),
  ],
);
