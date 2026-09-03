import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/features/home/providers/home_providers.dart';
import 'package:malssi/core/services/notification_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quoteAsync = context.watch<randomQuoteProvider>;
    final quotes = context.watch<likedQuotesStreamProvider>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 명언'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Notification service example
              final notif = context.read<NotificationService>();
              notif.scheduleNotification(
                id: DateTime.now().millisecondsSinceEpoch,
                title: '새로운 명언!',
                body: '오늘의 명언을 확인해보세요',
                scheduleTime: DateTime.now().add(const Duration(seconds: 5)),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: quoteAsync.when(
          data: (quote) => _buildQuoteCard(quote),
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text('Error: $err'),
        ),
      ),
      floatingActionButton: quoteAsync.when(
        data: (_) => FloatingActionButton(
          onPressed: () => context.read<QuoteNotifier>().likeCurrentQuote(),
          child: const Icon(Icons.favorite),
        ),
        loading: () => const CircularProgressIndicator(),
        error: (_) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildQuoteCard(Quote? quote) {
    if (quote == null) {
      return const Text('명언을 불러올 수 없습니다.');
    }
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quote.text,
              style: const TextStyle(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '— ${quote.author}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '💚 ${quote.likes}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.favorite, color: Colors.pink, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}