import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/features/quote.dart';

/// 번들 명언 에셋 로더 (#123).
/// `tool/classify_quotes.py`가 `assets/docs/wikiquote.json` (원본 719件)을
/// 7테마로 분류해 만든 `assets/docs/quotes.json`을 읽는다.
abstract class QuoteAssets {
  static const assetPath = 'assets/docs/quotes.json';

  /// 에셋 번들에서 명언 목록을 불러온다. 실패하면 빈 목록
  /// (호출 측이 기본 시드로 폴백한다).
  static Future<List<Quote>> loadQuotes([AssetBundle? bundle]) async {
    try {
      final raw = await (bundle ?? rootBundle).loadString(assetPath);
      return parseQuotes(raw);
    } catch (_) {
      return const [];
    }
  }

  /// quotes.json 파싱. 스키마 위반이면 [FormatException].
  static List<Quote> parseQuotes(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('quotes must be a list');
    }
    return [for (final entry in decoded) _parseQuote(entry)];
  }

  static Quote _parseQuote(dynamic entry) {
    if (entry is! Map) {
      throw FormatException('quote entry must be a map: $entry');
    }
    final id = entry['id'];
    final text = entry['text'];
    final author = entry['author'];
    final theme = entry['theme'];
    if (id is! String || id.isEmpty) {
      throw FormatException('invalid id: $entry');
    }
    if (text is! String || text.isEmpty) {
      throw FormatException('empty text: $entry');
    }
    if (author is! String) {
      throw FormatException('invalid author: $entry');
    }
    if (theme is! String || !SeedTheme.isValid(theme)) {
      throw FormatException('invalid theme: $entry');
    }
    return Quote(
      id: id,
      text: text,
      author: author,
      likes: 0,
      // 원문에 날짜가 없어 에셋 확정일로 둔다.
      createdAt: DateTime(2026, 9, 6),
      theme: theme,
    );
  }
}
