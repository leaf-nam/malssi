import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/home/providers/home_providers.dart';
import 'package:malssi/features/quote.dart';

/// Liked quotes list (bottom-nav "좋아요" tab).
class LikedScreen extends StatelessWidget {
  const LikedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quoteState = context.watch<QuoteProvider>();
    final likedIds = quoteState.likedQuoteIds.toSet();
    final repo = context.read<QuoteRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('좋아요한 명언')),
      body: FutureBuilder<List<Quote>>(
        future: repo.getQuotesStream().first,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final liked = snapshot.data!
              .where((q) => likedIds.contains(q.id))
              .toList();
          if (liked.isEmpty) {
            return const Center(
              child: Text('아직 좋아요한 명언이 없어요.\n홈에서 ♥를 눌러보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, height: 1.6, color: AppTheme.muted)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: liked.length,
            itemBuilder: (context, index) {
              final quote = liked[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  tileColor: AppTheme.ink850,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppTheme.line),
                  ),
                  title: Text('"${quote.text}"',
                      style: AppTheme.quoteTextStyle(fontSize: 14)),
                  subtitle: Text('— ${quote.author} · ♥ ${quote.likes}',
                      style:
                          const TextStyle(fontSize: 11, color: AppTheme.muted)),
                  onTap: () => context.go('/quote-detail/${quote.id}',
                      extra: quote),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const MvpBottomNav(currentIndex: 3),
    );
  }
}
