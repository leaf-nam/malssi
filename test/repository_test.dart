import 'package:flutter_test/flutter_test.dart';

import 'package:malssi/features/category/data/hashtag_repository.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/home/providers/home_providers.dart';
import 'package:malssi/features/my_quote/data/submission_repository.dart';
import 'package:malssi/features/quote_detail/data/comment_repository.dart';

void main() {
  group('QuoteProvider', () {
    test('fetchRandomQuote loads a seed quote', () async {
      final provider =
          QuoteProvider(repository: InMemoryQuoteRepository());
      await provider.fetchRandomQuote();

      expect(provider.currentQuote, isNotNull);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('likeCurrentQuote increments likes and tracks the id', () async {
      final provider =
          QuoteProvider(repository: InMemoryQuoteRepository());
      await provider.fetchRandomQuote();

      final before = provider.currentQuote!.likes;
      final id = provider.currentQuote!.id;
      await provider.likeCurrentQuote();

      expect(provider.currentQuote!.likes, before + 1);
      expect(provider.isLiked(id), isTrue);
    });
  });

  group('InMemoryCommentRepository', () {
    test('getBestComments returns top 3 by likes', () async {
      final repo = InMemoryCommentRepository();
      final best = await repo.getBestComments('seed-1');

      expect(best.length, 3);
      expect(best[0].likes, greaterThanOrEqualTo(best[1].likes));
      expect(best[1].likes, greaterThanOrEqualTo(best[2].likes));
    });

    test('addComment appends a comment', () async {
      final repo = InMemoryCommentRepository();
      final before = (await repo.getComments('seed-1')).length;

      await repo.addComment(quoteId: 'seed-1', author: '나', text: '좋아요');

      final after = await repo.getComments('seed-1');
      expect(after.length, before + 1);
      expect(after.first.text, '좋아요');
    });
  });

  group('InMemoryHashtagRepository', () {
    test('getHashtagCounts returns tags sorted by count desc', () async {
      final repo = InMemoryHashtagRepository();
      final counts = await repo.getHashtagCounts();

      expect(counts, isNotEmpty);
      expect(counts.first.name, '위로');
      for (var i = 1; i < counts.length; i++) {
        expect(counts[i - 1].count, greaterThanOrEqualTo(counts[i].count));
      }
    });
  });

  group('InMemorySubmissionRepository', () {
    test('submitQuote inserts a pending submission on top', () async {
      final repo = InMemorySubmissionRepository();
      await repo.submitQuote(text: '새 문장', author: '본인', category: '성장');

      final mine = await repo.getMySubmissions();
      expect(mine.first.text, '새 문장');
      expect(mine.first.status, SubmissionStatus.pending);
    });
  });
}
