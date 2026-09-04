/// 명언·씨앗·열매 테마 정규 키 7종 (`docs/context/model_spec.md` §4.11).
/// enum 대신 문자열 상수로 둔다 (Firestore 직렬화 단순화, `SeedStatus`와 동일 패턴).
abstract class SeedTheme {
  static const vitality = 'vitality';
  static const happiness = 'happiness';
  static const growth = 'growth';
  static const health = 'health';
  static const peace = 'peace';
  static const relationship = 'relationship';
  static const wisdom = 'wisdom';

  static const values = [
    vitality,
    happiness,
    growth,
    health,
    peace,
    relationship,
    wisdom,
  ];

  static bool isValid(String value) => values.contains(value);
}
