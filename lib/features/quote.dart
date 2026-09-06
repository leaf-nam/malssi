class Quote {
  final String id;
  final String text;
  final String author;
  final int likes;
  final DateTime createdAt;

  /// 테마 분류 키 (`SeedTheme` 값 중 1개, 미분류는 `''`).
  final String theme;

  /// 명언 출처 표시문 (예: `한국어 위키인용집 (CC BY-SA 4.0)`).
  /// 비어 있으면 출처 버튼을 노출하지 않는다 (#123).
  final String source;

  const Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.likes,
    required this.createdAt,
    this.theme = '',
    this.source = '',
  });

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      author: map['author'] ?? '',
      likes: map['likes'] ?? 0,
      createdAt: (map['createdAt'] as dynamic).toDate() ?? DateTime.now(),
      theme: map['theme'] ?? '',
      source: map['source'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'likes': likes,
      'createdAt': createdAt,
      'theme': theme,
      'source': source,
    };
  }

  Quote copyWith({
    String? id,
    String? text,
    String? author,
    int? likes,
    DateTime? createdAt,
    String? theme,
    String? source,
  }) {
    return Quote(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      theme: theme ?? this.theme,
      source: source ?? this.source,
    );
  }
}
