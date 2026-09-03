import 'package:flutter/foundation.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/quote.dart';

/// Minimal [ChangeNotifier]-based state for the home screen.
///
/// Uses the `provider` package (see `AppShell`) instead of riverpod until
/// the state-management direction in `docs/conventions/convention.md` is settled.
class QuoteProvider extends ChangeNotifier {
  QuoteProvider({required this._repository});

  final QuoteRepository _repository;

  Quote? _currentQuote;
  Quote? get currentQuote => _currentQuote;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final Set<String> _likedQuoteIds = {};
  bool isLiked(String quoteId) => _likedQuoteIds.contains(quoteId);

  List<String> get likedQuoteIds => List.unmodifiable(_likedQuoteIds);

  final int _streakDays = 7;
  int get streakDays => _streakDays;

  Future<void> fetchRandomQuote() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentQuote = await _repository.getRandomQuote();
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> likeCurrentQuote() async {
    final quote = _currentQuote;
    if (quote == null) return;
    try {
      _currentQuote = await _repository.updateLike(quote.id);
      _likedQuoteIds.add(quote.id);
      notifyListeners();
    } catch (e) {
      _errorMessage = '$e';
      notifyListeners();
    }
  }
}
