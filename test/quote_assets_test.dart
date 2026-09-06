import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/features/home/data/quote_assets.dart';

void main() {
  group('QuoteAssets.parseQuotes', () {
    test('parses entries and rejects bad themes', () {
      final quotes = QuoteAssets.parseQuotes(jsonEncode([
        {'id': 'a', 'text': 't', 'author': 'a', 'theme': 'growth'},
      ]));

      expect(quotes.single.theme, 'growth');
      expect(
        () => QuoteAssets.parseQuotes(jsonEncode([
          {'id': 'a', 'text': 't', 'author': 'a', 'theme': 'nope'},
        ])),
        throwsFormatException,
      );
      expect(
        () => QuoteAssets.parseQuotes(jsonEncode([
          {'id': 'a', 'text': '', 'author': 'a', 'theme': 'growth'},
        ])),
        throwsFormatException,
      );
    });
  });

  group('assets/docs/quotes.json', () {
    test('covers all source quotes with valid themes (#123)', () {
      final source = (jsonDecode(
        File('assets/docs/wikiquote.json').readAsStringSync(),
      ) as List)
          .length;
      final quotes = QuoteAssets.parseQuotes(
        File('assets/docs/quotes.json').readAsStringSync(),
      );

      expect(quotes.length, source);
      for (final quote in quotes) {
        expect(quote.text.isNotEmpty, isTrue);
        expect(SeedTheme.isValid(quote.theme), isTrue);
      }
      final ids = quotes.map((quote) => quote.id).toSet();
      expect(ids.length, quotes.length);
    });

    test('every theme has enough quotes (#123)', () {
      final quotes = QuoteAssets.parseQuotes(
        File('assets/docs/quotes.json').readAsStringSync(),
      );
      final counts = <String, int>{};
      for (final quote in quotes) {
        counts[quote.theme] = (counts[quote.theme] ?? 0) + 1;
      }
      for (final theme in SeedTheme.values) {
        expect(counts[theme] ?? 0, greaterThanOrEqualTo(20));
      }
    });
  });
}
