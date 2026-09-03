class Quote {
  final String id;
  final String text;
  final String author;
  final int likes;
  final DateTime createdAt;
  final List<String> tags;

  const Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.likes,
    required this.createdAt,
    this.tags = const [],
  });

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      author: map['author'] ?? '',
      likes: map['likes'] ?? 0,
      createdAt: (map['createdAt'] as dynamic).toDate() ?? DateTime.now(),
      tags: List<String>.from(map['tags'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'likes': likes,
      'createdAt': createdAt,
      'tags': tags,
    };
  }

  Quote copyWith({
    String? id,
    String? text,
    String? author,
    int? likes,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return Quote(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }
}
