import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommentScreen extends StatelessWidget {
  const CommentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final comments = context.watch<likedQuotesStreamProvider>(); // placeholder

    return Scaffold(
      appBar: AppBar(
        title: const Text('명언 상세 + 댓글'),
      ),
      body: Center(
        child: const Text('Comment Screen - Coming Soon'),
      ),
    );
  }
}