abstract class QuoteRepository {
  Future<Quote> getRandomQuote();

  Stream<List<Quote>> getQuotesStream();

  Future<Quote> addQuote(Quote quote);

  Future<Quote> updateLike(String quoteId);

  Future<void> deleteQuote(String quoteId);
}