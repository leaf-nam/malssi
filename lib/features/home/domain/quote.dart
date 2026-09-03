import 'package:malssi/features/quote.dart';

class HomeQuote extends Quote {
  final String category;
  final bool isFeatured;

  const HomeQuote({
    required super.id,
    required super.text,
    required super.author,
    required super.likes,
    required super.createdAt,
    super.tags = const [],
    required this.category,
    required this.isFeatured,
  });

  factory HomeQuote.fromMap(Map<String, dynamic> map) {
    return HomeQuote(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      author: map['author'] ?? '',
      likes: map['likes'] ?? 0,
      createdAt: (map['createdAt'] as dynamic).toDate() ?? DateTime.now(),
      tags: List<String>.from(map['tags'] ?? const []),
      category: map['category'] ?? '',
      isFeatured: map['isFeatured'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'category': category,
      'isFeatured': isFeatured,
    };
  }

  @override
  HomeQuote copyWith({
    String? id,
    String? text,
    String? author,
    int? likes,
    DateTime? createdAt,
    List<String>? tags,
    String? category,
    bool? isFeatured,
  }) {
    return HomeQuote(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}
