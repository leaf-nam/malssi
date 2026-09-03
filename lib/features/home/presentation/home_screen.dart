import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/services/notification_service.dart';
import 'package:malssi/features/home/providers/home_providers.dart';
import 'package:malssi/features/quote.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quoteState = context.watch<QuoteProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 명언'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
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
      body: Center(child: _buildBody(quoteState)),
      floatingActionButton: FloatingActionButton(
        onPressed: quoteState.currentQuote == null ? null : () => context.read<QuoteProvider>().likeCurrentQuote(),
        child: const Icon(Icons.favorite),
      ),
    );
  }

  Widget _buildBody(QuoteProvider quoteState) {
    if (quoteState.isLoading && quoteState.currentQuote == null) {
      return const CircularProgressIndicator();
    }
    if (quoteState.errorMessage != null && quoteState.currentQuote == null) {
      return Text('Error: ${quoteState.errorMessage}');
    }
    return _buildQuoteCard(quoteState.currentQuote);
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
            const SizedBox(height: 12),
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
