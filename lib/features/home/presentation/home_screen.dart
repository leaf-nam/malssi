import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:malssi/core/services/ad_service.dart';
import 'package:malssi/core/services/notification_service.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';
import 'package:malssi/features/home/providers/home_providers.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/quote_detail/data/comment_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _watchAdAndNext(BuildContext context) async {
    final quoteProvider = context.read<QuoteProvider>();
    final adService = AdService.instance;
    await adService.loadAd();
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('광고 시청 중... (15초)')),
          ],
        ),
      ),
    );
    await adService.showAd();
    await quoteProvider.fetchRandomQuote();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _share(Quote quote) async {
    await Share.share(
      '오늘의 한 문장\n"${quote.text}" — ${quote.author}\nhttps://malssi.app/quote/${quote.id}',
      subject: '명언 공유하기',
    );
  }

  @override
  Widget build(BuildContext context) {
    final quoteState = context.watch<QuoteProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('한 줄', style: TextStyle(fontFamily: 'serif')),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              final notif = context.read<NotificationService>();
              notif.scheduleNotification(
                id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                title: '새로운 명언!',
                body: '오늘의 명언을 확인해보세요',
                scheduleTime: DateTime.now().add(const Duration(seconds: 5)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Ribbon(label: '오늘의 명언'),
            _buildQuoteCard(context, quoteState),
            _buildActionRow(context, quoteState),
            _buildNextButton(context),
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              child: Text(
                '${quoteState.streakDays}일 연속으로 오늘의 명언을 읽었어요',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: AppTheme.muted),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MvpBottomNav(currentIndex: 0),
    );
  }

  Widget _buildQuoteCard(BuildContext context, QuoteProvider quoteState) {
    if (quoteState.isLoading && quoteState.currentQuote == null) {
      return const SizedBox(
        height: 230,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final quote = quoteState.currentQuote;
    if (quoteState.errorMessage != null && quote == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Error: ${quoteState.errorMessage}'),
      );
    }
    if (quote == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('명언을 불러올 수 없습니다.'),
      );
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
      decoration: BoxDecoration(
        color: AppTheme.ink800,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"${quote.text}"', style: AppTheme.quoteTextStyle()),
          const SizedBox(height: 18),
          Text(
            '— ${quote.author}',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (quote.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in quote.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF3A4A40)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(fontSize: 11, color: AppTheme.sage),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, QuoteProvider quoteState) {
    final quote = quoteState.currentQuote;
    final liked = quote != null && quoteState.isLiked(quote.id);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.line),
          bottom: BorderSide(color: AppTheme.line),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Action(
            glyph: liked ? '♥' : '♡',
            label: '좋아요 ${quote?.likes ?? 0}',
            highlight: liked,
            onTap: quote == null ? null : () => context.read<QuoteProvider>().likeCurrentQuote(),
          ),
          InkWell(
            onTap: quote == null
                ? null
                : () => context.go('/quote-detail/${quote.id}', extra: quote),
            child: Column(
              children: [
                const Text('💬', style: TextStyle(fontSize: 18, color: AppTheme.paper)),
                const SizedBox(height: 5),
                if (quote != null)
                  CommentCountBadge(quoteId: quote.id)
                else
                  const Text('댓글', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
              ],
            ),
          ),
          _Action(
            glyph: '↗',
            label: '공유',
            onTap: quote == null ? null : () => _share(quote),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.goldDim),
          foregroundColor: AppTheme.gold,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => _watchAdAndNext(context),
        child: const Column(
          children: [
            Text('광고 보고 다음 명언 받기',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(height: 3),
            Text('15초 영상 시청 후 새 문장이 열립니다',
                style: TextStyle(fontSize: 10.5, color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 22, 0, 0),
        padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
        decoration: const BoxDecoration(
          color: AppTheme.gold,
          borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF211705),
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.glyph,
    required this.label,
    this.highlight = false,
    this.onTap,
  });

  final String glyph;
  final String label;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            glyph,
            style: TextStyle(
              fontSize: 18,
              color: highlight ? AppTheme.gold : AppTheme.paper,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
        ],
      ),
    );
  }
}

/// Comment count shown on the home action row.
class CommentCountBadge extends StatelessWidget {
  const CommentCountBadge({super.key, required this.quoteId});

  final String quoteId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CommentRepository>();
    return FutureBuilder(
      future: repo.getComments(quoteId),
      builder: (context, snapshot) => Text(
        '댓글 ${snapshot.data?.length ?? 0}',
        style: const TextStyle(fontSize: 11, color: AppTheme.muted),
      ),
    );
  }
}
