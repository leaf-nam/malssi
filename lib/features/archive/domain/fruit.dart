class Fruit {
  final String id;
  final String seedId;
  final String quoteId;
  final String text;
  final String author;
  final DateTime harvestedAt;

  /// 수확 시점의 테마 스냅샷 (`SeedTheme` 값 중 1개, 미분류는 `''`).
  final String theme;

  const Fruit({
    required this.id,
    required this.seedId,
    required this.quoteId,
    required this.text,
    required this.author,
    required this.harvestedAt,
    this.theme = '',
  });

  factory Fruit.fromMap(Map<String, dynamic> map) {
    return Fruit(
      id: map['id'] ?? '',
      seedId: map['seedId'] ?? '',
      quoteId: map['quoteId'] ?? '',
      text: map['text'] ?? '',
      author: map['author'] ?? '',
      harvestedAt:
          (map['harvestedAt'] as dynamic).toDate() ?? DateTime.now(),
      theme: map['theme'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seedId': seedId,
      'quoteId': quoteId,
      'text': text,
      'author': author,
      'harvestedAt': harvestedAt,
      'theme': theme,
    };
  }

  Fruit copyWith({
    String? id,
    String? seedId,
    String? quoteId,
    String? text,
    String? author,
    DateTime? harvestedAt,
    String? theme,
  }) {
    return Fruit(
      id: id ?? this.id,
      seedId: seedId ?? this.seedId,
      quoteId: quoteId ?? this.quoteId,
      text: text ?? this.text,
      author: author ?? this.author,
      harvestedAt: harvestedAt ?? this.harvestedAt,
      theme: theme ?? this.theme,
    );
  }
}
