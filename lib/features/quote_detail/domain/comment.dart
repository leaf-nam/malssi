abstract class Comment {
  final String id;
  final String quoteId;
  final String author;
  final String text;
  final int likes;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.quoteId,
    required this.author,
    required this.text,
    required this.likes,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment._internal(
      id: map['id'] ?? '',
      quoteId: map['quoteId'] ?? '',
      author: map['author'] ?? '',
      text: map['text'] ?? '',
      likes: map['likes'] ?? 0,
      createdAt: (map['createdAt'] as dynamic).toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quoteId': quoteId,
      'author': author,
      'text': text,
      'likes': likes,
      'createdAt': createdAt,
    };
  }

  Comment copyWith({
    String? id,
    String? quoteId,
    String? author,
    String? text,
    int? likes,
    DateTime? createdAt,
  }) {
    return Comment._internal(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      author: author ?? this.author,
      text: text ?? this.text,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Comment._internal({
  required String id,
  required String quoteId,
  required String author,
  required String text,
  required int likes,
  required DateTime createdAt,
}) implements Comment {
  @override
  final String id;
  @override
  final String quoteId;
  @override
  final String author;
  @override
  final String text;
  @override
  final int likes;
  @override
  final DateTime createdAt;
}