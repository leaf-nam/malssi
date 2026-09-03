import 'package:riverpod/flutter_riverpod.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/home/domain/quote.dart';

// Provider for random quote
final randomQuoteProvider = StateNotifierProvider<QuoteNotifier, Quote?>((ref) {
  final repo = QuoteRepositoryImpl();
  return QuoteNotifier(repository: repo)..fetchRandomQuote();
});

// Notifier for quote state
class QuoteNotifier extends StateNotifier<Quote?> {
  final QuoteRepository _repository;
  
  QuoteNotifier({required QuoteRepository repository}) : _repository = repository, super(null);

  Future<void> fetchRandomQuote() async {
    state = await _repository.getRandomQuote();
  }

  Future<void> likeCurrentQuote() async {
    if (state != null) {
      state = await _repository.updateLike(state!.id);
    }
  }
}

// Provider for liked quotes stream
final likedQuotesStreamProvider = StreamProvider<List<Quote>>((ref) {
  final repo = QuoteRepositoryImpl();
  return repo.getQuotesStream();
});