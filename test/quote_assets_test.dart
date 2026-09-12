import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/features/home/data/quote_assets.dart';

void main() {
  group('QuoteAssets.parseQuotes', () {
    test('parses entries and rejects bad themes', () {
      const source = '한국어 위키인용집 (CC BY-SA 4.0)';
      final quotes = QuoteAssets.parseQuotes(jsonEncode([
        {
          'id': 'a',
          'text': 't',
          'author': 'a',
          'theme': 'growth',
          'source': source
        },
      ]));

      expect(quotes.single.theme, 'growth');
      expect(quotes.single.source, source);
      expect(
        () => QuoteAssets.parseQuotes(jsonEncode([
              {
                'id': 'a',
                'text': 't',
                'author': 'a',
                'theme': 'nope',
                'source': source
              }
            ])),
        throwsFormatException,
      );
      expect(
        () => QuoteAssets.parseQuotes(jsonEncode([
              {
                'id': 'a',
                'text': '',
                'author': 'a',
                'theme': 'growth',
                'source': source
              }
            ])),
        throwsFormatException,
      );
      expect(
        () => QuoteAssets.parseQuotes(jsonEncode([
              {
                'id': 'a',
                'text': 't',
                'author': 'a',
                'theme': 'growth',
                'source': 7
              }
            ])),
        throwsFormatException,
      );
    });

    test('harvested quotes keep their source (#123)', () {
      final quotes = QuoteAssets.parseQuotes(
        File('assets/docs/quotes.json').readAsStringSync(),
      );

      expect(quotes, isNotEmpty);
      for (final quote in quotes) {
        expect(quote.source.isNotEmpty, isTrue);
      }
    });
  });

  group('assets/docs/quotes.json', () {
    test('is a curated subset of the sources with valid themes (#123)',
        () {
      final sourceIds = (jsonDecode(
        File('assets/docs/wikiquote.json').readAsStringSync(),
      ) as List)
          .map((entry) => (entry as Map)['dedup_key'])
          .toSet();
      final quotes = QuoteAssets.parseQuotes(
        File('assets/docs/quotes.json').readAsStringSync(),
      );

      // 큐레이션으로 걸러져 원본의 부분집합이다.
      // 속담(#176)은 위키가 아닌 우리말샘 원천이라 id가 없어도 된다.
      expect(quotes.isNotEmpty, isTrue);
      for (final quote in quotes) {
        if (quote.source == '국립국어원 우리말샘') continue;
        expect(sourceIds, contains(quote.id));
      }
      for (final quote in quotes) {
        expect(quote.text.isNotEmpty, isTrue);
        expect(SeedTheme.isValid(quote.theme), isTrue);
        // 표시용 문구는 250자를 넘지 않는다 (초과는 핵심문장으로 단축).
        expect(quote.text.length, lessThanOrEqualTo(250));
      }
      final ids = quotes.map((quote) => quote.id).toSet();
      expect(ids.length, quotes.length);
    });

    test('proverbs bundle keeps 88 curated entries (#176)', () {
      final quotes = QuoteAssets.parseQuotes(
        File('assets/docs/quotes.json').readAsStringSync(),
      );
      final proverbs =
          quotes.where((q) => q.source == '국립국어원 우리말샘').toList();

      expect(proverbs.length, 88);
      final counts = <String, int>{};
      for (final quote in proverbs) {
        expect(quote.author, '우리말 속담');
        expect(SeedTheme.isValid(quote.theme), isTrue);
        counts[quote.theme] = (counts[quote.theme] ?? 0) + 1;
      }
      // 선정 분포 고정 (리뷰 제외 12건 반영:
      // 활력 10·행복 9·성장 13·건강 12·평온 14·관계 15·지혜 15).
      expect(counts, {
        'vitality': 10,
        'happiness': 9,
        'growth': 13,
        'health': 12,
        'peace': 14,
        'relationship': 15,
        'wisdom': 15,
      });
    });

    test('every theme has enough quotes (#123)', () {
      final quotes = QuoteAssets.parseQuotes(
        File('assets/docs/quotes.json').readAsStringSync(),
      );
      final counts = <String, int>{};
      for (final quote in quotes) {
        counts[quote.theme] = (counts[quote.theme] ?? 0) + 1;
      }
      // 엄선 후 규모: 전件 100件 이상, 테마별 5件 이상을 유지한다.
      expect(quotes.length, greaterThanOrEqualTo(100));
      for (final theme in SeedTheme.values) {
        expect(counts[theme] ?? 0, greaterThanOrEqualTo(5));
      }
    });
  });
}
