import 'package:flutter_test/flutter_test.dart';

import 'package:malssi/core/widgets/word_wrap.dart';

void main() {
  group('keepWordsTogether (#177)', () {
    test('joins Hangul syllables inside words', () {
      expect(
        keepWordsTogether('오늘의 씨앗이'),
        '오\u2060늘\u2060의 씨\u2060앗\u2060이',
      );
    });

    test('leaves Latin and punctuation breaks alone', () {
      // 영문 단어 안에는 넣지 않고, 한글·숫자 사이만 잇는다.
      expect(keepWordsTogether('seed 123'), 'seed 1\u20602\u20603');
      expect(keepWordsTogether('말씨, 성장!'), '말\u2060씨, 성\u2060장!');
      expect(keepWordsTogether('2시까지만'), '2\u2060시\u2060까\u2060지\u2060만');
    });

    test('empty and single-char strings pass through', () {
      expect(keepWordsTogether(''), '');
      expect(keepWordsTogether('꽃'), '꽃');
      expect(keepWordsTogether('a b'), 'a b');
    });
  });
}
