import 'dart:math';

import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/core/services/local_store.dart';
import 'package:malssi/features/quote.dart';

abstract class QuoteRepository {
  Future<Quote> getRandomQuote();

  /// [theme] 테마의 명언 중 랜덤 1개. 해당 테마가 없으면 전체에서 랜덤 (폴백).
  /// [excludeIds]에 든 명언은 후보에서 제외한다 (#265).
  Future<Quote> getRandomQuoteByTheme(
    String theme, {
    Set<String> excludeIds = const {},
  });

  /// 공개된 번들 명언 ID를 이력에 기록한다 (#265).
  /// 자작 명언(`custom-`)은 기록하지 않는다.
  Future<void> markShown(String quoteId);

  Stream<List<Quote>> getQuotesStream();

  Future<Quote> addQuote(Quote quote);

  Future<Quote> updateLike(String quoteId);

  Future<void> deleteQuote(String quoteId);
}

/// In-memory implementation backed by the bundled asset (#123).
/// No backend; seed data only with no persistence across restarts.
class InMemoryQuoteRepository implements QuoteRepository {
  InMemoryQuoteRepository({List<Quote>? seed, this._store})
      : _quotes = List.of(
            seed == null || seed.isEmpty ? _defaultSeed : seed);

  static final List<Quote> _defaultSeed = [
    Quote(
      id: 'seed-1',
      text: '멀리 가려면 함께 가라.',
      author: '아프리카 속담',
      likes: 128,
      createdAt: DateTime(2026, 1, 1),
      theme: SeedTheme.relationship,
    ),
    Quote(
      id: 'seed-2',
      text: '천 리 길도 한 걸음부터.',
      author: '노자',
      likes: 96,
      createdAt: DateTime(2026, 1, 2),
      theme: SeedTheme.growth,
    ),
    Quote(
      id: 'seed-3',
      text: '어두울 때 별이 빛난다.',
      author: '랄프 왈도 에머슨',
      likes: 74,
      createdAt: DateTime(2026, 1, 3),
      theme: SeedTheme.peace,
    ),
    Quote(
      id: 'seed-4',
      text: '시작이 반이다.',
      author: '한국 속담',
      likes: 61,
      createdAt: DateTime(2026, 1, 4),
      theme: SeedTheme.vitality,
    ),
    Quote(
      id: 'seed-5',
      text: '웃는 집에 복이 온다.',
      author: '한국 속담',
      likes: 58,
      createdAt: DateTime(2026, 1, 5),
      theme: SeedTheme.happiness,
    ),
    Quote(
      id: 'seed-6',
      text: '건강을 잃으면 모든 것을 잃는다.',
      author: '한국 속담',
      likes: 52,
      createdAt: DateTime(2026, 1, 6),
      theme: SeedTheme.health,
    ),
    Quote(
      id: 'seed-7',
      text: '아는 것이 힘이다.',
      author: '프랜시스 베이컨',
      likes: 49,
      createdAt: DateTime(2026, 1, 7),
      theme: SeedTheme.wisdom,
    ),
  ];

  final List<Quote> _quotes;
  final Random _random = Random();

  /// 로컬 저장소 (#265). `null`이면 세션 내 이력만 사용한다.
  final LocalStore? _store;

  /// 이미 공개된 번들 명언 ID.
  final Set<String> _shownIds = {};

  /// 저장된 노출 이력을 불러온다. `main()` 시작 시 1회 호출한다.
  Future<void> load() async {
    final store = _store;
    if (store == null) return;
    final raw = await store.readMap(StoreKeys.shownQuotes);
    final ids = raw['ids'];
    if (ids is List) {
      _shownIds
        ..clear()
        ..addAll(ids.whereType<String>());
    }
  }

  Future<void> _persistShown() async {
    final store = _store;
    if (store == null) return;
    await store.writeMap(StoreKeys.shownQuotes, {
      'ids': _shownIds.toList(),
    });
  }

  @override
  Future<Quote> getRandomQuote() async {
    if (_quotes.isEmpty) {
      throw StateError('No quotes available');
    }
    return _quotes[_random.nextInt(_quotes.length)];
  }

  @override
  Future<Quote> getRandomQuoteByTheme(
    String theme, {
    Set<String> excludeIds = const {},
  }) async {
    final themed = _quotes.where((q) => q.theme == theme).toList();
    final pool = themed.isEmpty ? _quotes : themed;
    var candidates = pool
        .where((q) => !_shownIds.contains(q.id) && !excludeIds.contains(q.id))
        .toList();
    if (candidates.isEmpty) {
      // 해당 테마를 모두 봤다면 이력만 초기화하고 다시 순환한다.
      _shownIds.removeAll(pool.map((q) => q.id));
      await _persistShown();
      candidates = pool.where((q) => !excludeIds.contains(q.id)).toList();
    }
    if (candidates.isEmpty) {
      return getRandomQuote();
    }
    return candidates[_random.nextInt(candidates.length)];
  }

  @override
  Future<void> markShown(String quoteId) async {
    if (quoteId.isEmpty || quoteId.startsWith('custom-')) return;
    if (_shownIds.add(quoteId)) {
      await _persistShown();
    }
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
