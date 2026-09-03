import 'dart:math';

import 'package:malssi/features/quote.dart';

abstract class QuoteRepository {
  Future<Quote> getRandomQuote();

  Stream<List<Quote>> getQuotesStream();

  Future<Quote> addQuote(Quote quote);

  Future<Quote> updateLike(String quoteId);

  Future<void> deleteQuote(String quoteId);
}

/// In-memory implementation used until the Firestore backend is connected.
/// Seed data only; no persistence across restarts.
class InMemoryQuoteRepository implements QuoteRepository {
  InMemoryQuoteRepository({List<Quote>? seed}) : _quotes = List.of(seed ?? _defaultSeed);

  static final List<Quote> _defaultSeed = [
    Quote(
      id: 'seed-1',
      text: '멀리 가려면 함께 가라.',
      author: '아프리카 속담',
      likes: 128,
      createdAt: DateTime(2026, 1, 1),
      tags: const ['협력', '관계'],
    ),
    Quote(
      id: 'seed-2',
      text: '천 리 길도 한 걸음부터.',
      author: '노자',
      likes: 96,
      createdAt: DateTime(2026, 1, 2),
      tags: const ['도전', '인내'],
    ),
    Quote(
      id: 'seed-3',
      text: '어두울 때 별이 빛난다.',
      author: '랄프 왈도 에머슨',
      likes: 74,
      createdAt: DateTime(2026, 1, 3),
      tags: const ['위로', '성장'],
    ),
    Quote(
      id: 'seed-4',
      text: '시작이 반이다.',
      author: '한국 속담',
      likes: 61,
      createdAt: DateTime(2026, 1, 4),
      tags: const ['도전'],
    ),
  ];

  final List<Quote> _quotes;
  final Random _random = Random();

  @override
  Future<Quote> getRandomQuote() async {
    if (_quotes.isEmpty) {
      throw StateError('No quotes available');
    }
    return _quotes[_random.nextInt(_quotes.length)];
  }

  @override
  Stream<List<Quote>> getQuotesStream() => Stream.value(List.unmodifiable(_quotes));

  @override
  Future<Quote> addQuote(Quote quote) async {
    _quotes.add(quote);
    return quote;
  }

  @override
  Future<Quote> updateLike(String quoteId) async {
    final index = _quotes.indexWhere((q) => q.id == quoteId);
    if (index == -1) {
      throw StateError('Quote not found: $quoteId');
    }
    final updated = _quotes[index].copyWith(likes: _quotes[index].likes + 1);
    _quotes[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteQuote(String quoteId) async {
    _quotes.removeWhere((q) => q.id == quoteId);
  }
}
