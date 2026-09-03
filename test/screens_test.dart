import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:malssi/features/category/data/hashtag_repository.dart';
import 'package:malssi/features/category/presentation/category_screen.dart';
import 'package:malssi/features/category/providers/category_providers.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/home/providers/home_providers.dart';
import 'package:malssi/features/liked/presentation/liked_screen.dart';
import 'package:malssi/features/my_quote/data/submission_repository.dart';
import 'package:malssi/features/my_quote/presentation/write_screen.dart';
import 'package:malssi/features/my_quote/providers/write_providers.dart';
import 'package:malssi/features/mypage/data/user_repository.dart';
import 'package:malssi/features/mypage/presentation/mypage_screen.dart';
import 'package:malssi/features/mypage/providers/user_providers.dart';
import 'package:malssi/features/quote_detail/data/comment_repository.dart';
import 'package:malssi/features/quote_detail/presentation/comment_screen.dart';
import 'package:malssi/features/quote_detail/providers/comment_providers.dart';

Widget _wrap(Widget child, {List<ChangeNotifierProvider>? extra}) {
  return MultiProvider(
    providers: [
      Provider<QuoteRepository>.value(value: InMemoryQuoteRepository()),
      Provider<CommentRepository>.value(
          value: InMemoryCommentRepository()),
      ChangeNotifierProvider(
        create: (_) =>
            QuoteProvider(repository: InMemoryQuoteRepository()),
      ),
      ChangeNotifierProvider(
        create: (_) =>
            UserProfileProvider(repository: DummyUserRepository())..load(),
      ),
      ChangeNotifierProvider(
        create: (_) =>
            CommentProvider(repository: InMemoryCommentRepository()),
      ),
      ChangeNotifierProvider(
        create: (_) =>
            CategoryProvider(repository: InMemoryHashtagRepository()),
      ),
      ChangeNotifierProvider(
        create: (_) =>
            WriteProvider(repository: InMemorySubmissionRepository()),
      ),
      ...?extra,
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('Category screen shows hashtag grid', (tester) async {
    await tester.pumpWidget(_wrap(const CategoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('#위로'), findsWidgets);
    expect(find.text('태그 전체'), findsOneWidget);
  });

  testWidgets('Write screen shows form and status list', (tester) async {
    await tester.pumpWidget(_wrap(const WriteScreen()));
    await tester.pumpAndSettle();

    expect(find.text('심사 요청하기'), findsOneWidget);
    expect(find.text('내가 제출한 명언'), findsOneWidget);
    expect(find.textContaining('넘어진 김에'), findsOneWidget);
  });

  testWidgets('MyPage shows profile and notification toggle', (tester) async {
    await tester.pumpWidget(_wrap(const MyPageScreen()));
    await tester.pumpAndSettle();

    expect(find.text('마이페이지'), findsOneWidget);
    expect(find.text('하루 1회 알림'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('Liked screen shows empty state', (tester) async {
    await tester.pumpWidget(_wrap(const LikedScreen()));
    await tester.pumpAndSettle();

    expect(find.text('좋아요한 명언'), findsOneWidget);
    expect(find.textContaining('아직 좋아요한 명언이 없어요'), findsOneWidget);
  });

  testWidgets('Comment screen shows best comments', (tester) async {
    await tester.pumpWidget(_wrap(const CommentScreen(quoteId: 'seed-1')));
    await tester.pumpAndSettle();

    expect(find.text('명언 상세'), findsOneWidget);
    expect(find.text('베스트 댓글'), findsOneWidget);
    expect(find.text('BEST'), findsNWidgets(3));
  });
}
