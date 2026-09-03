import 'package:flutter/material.dart';

/// Placeholder for the quote-detail + comments screen.
/// Comment list, best-3 query and write UI are tracked in the feature spec
/// (`docs/features/feature_spec.md` §3) and will be implemented separately.
class CommentScreen extends StatelessWidget {
  const CommentScreen({super.key, this.quoteId = ''});

  final String quoteId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('명언 상세 + 댓글'),
      ),
      body: Center(
        child: Text('Comment Screen - Coming Soon\nquoteId: $quoteId'),
      ),
    );
  }
}
