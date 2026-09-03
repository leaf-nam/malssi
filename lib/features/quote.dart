abstract class Quote {
  final String id;
  final String text;
  final String author;
  final int likes;
  final DateTime createdAt;

  const Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.likes,
    required this.createdAt,
  });

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote._internal(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      author: map['author'] ?? '',
      likes: map['likes'] ?? 0,
      createdAt: (map['createdAt'] as dynamic).toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'likes': likes,
      'createdAt': createdAt,
    };
  }

  Quote copyWith({
    String? id,
    String? text,
    String? author,
    int? likes,
    DateTime? createdAt,
  }) {
    return Quote._internal(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Quote._internal({
  required String id,
  required String text,
  required String author,
  required int likes,
  required DateTime createdAt,
}) implements Quote {
  @override
  final String id;
  @override
  final String text;
  @override
  final String author;
  @override
  final int likes;
  @override
  final DateTime createdAt;
}