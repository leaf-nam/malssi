import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/quote_detail/domain/comment.dart';
import 'package:malssi/features/quote_detail/providers/comment_providers.dart';

class CommentScreen extends StatefulWidget {
  const CommentScreen({super.key, this.quoteId = '', this.quote});

  final String quoteId;
  final Quote? quote;

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().load(widget.quoteId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comments = context.watch<CommentProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Text('←', style: TextStyle(fontSize: 16)),
          onPressed: () => context.go('/'),
        ),
        title: const Text('명언 상세'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMiniQuote(),
                  _SectionLabel(
                    left: '베스트 댓글',
                    right: '${comments.recent.length}개 전체보기',
                  ),
                  if (comments.isLoading && comments.best.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (comments.best.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text('아직 댓글이 없어요. 첫 댓글을 남겨보세요.',
                          style: TextStyle(fontSize: 13, color: AppTheme.muted)),
                    )
                  else
                    for (final c in comments.best) _CommentCard(comment: c, best: true),
                  const _SectionLabel(left: '최근 댓글'),
                  for (final c in comments.recent)
                    _CommentCard(comment: c, best: false),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          _buildInput(context),
        ],
      ),
      bottomNavigationBar: const MvpBottomNav(currentIndex: 0),
    );
  }

  Widget _buildMiniQuote() {
    final quote = widget.quote;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.ink800,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: quote == null
          ? Text('quoteId: ${widget.quoteId}',
              style: const TextStyle(fontSize: 13, color: AppTheme.muted))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('"${quote.text}"',
                    style: AppTheme.quoteTextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text('— ${quote.author}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: const BoxDecoration(
        color: AppTheme.ink900,
        border: Border(top: BorderSide(color: AppTheme.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.paper),
              decoration: const InputDecoration(
                hintText: '댓글을 남겨보세요',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onSubmitted: (_) => _submit(context),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _submit(context),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await context.read<CommentProvider>().addComment(text);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.left, this.right});

  final String left;
  final String? right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.paper,
                fontWeight: FontWeight.w600,
              )),
          if (right != null)
            Text(right!,
                style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment, required this.best});

  final Comment comment;
  final bool best;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.ink850,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (best)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('BEST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF211705),
                      )),
                ),
              Text(comment.author,
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
            ],
          ),
          const SizedBox(height: 5),
          Text(comment.text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: AppTheme.paper,
              )),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () =>
                context.read<CommentProvider>().likeComment(comment.id),
            child: Text(
              '좋아요 ${comment.likes}',
              style: const TextStyle(fontSize: 11, color: AppTheme.muted),
            ),
          ),
        ],
      ),
    );
  }
}
