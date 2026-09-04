class Fruit {
  final String id;
  final String seedId;
  final String quoteId;
  final String text;
  final String author;
  final DateTime harvestedAt;

  const Fruit({
    required this.id,
    required this.seedId,
    required this.quoteId,
    required this.text,
    required this.author,
    required this.harvestedAt,
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
    };
  }

  Fruit copyWith({
    String? id,
    String? seedId,
    String? quoteId,
    String? text,
    String? author,
    DateTime? harvestedAt,
  }) {
    return Fruit(
      id: id ?? this.id,
      seedId: seedId ?? this.seedId,
      quoteId: quoteId ?? this.quoteId,
      text: text ?? this.text,
      author: author ?? this.author,
      harvestedAt: harvestedAt ?? this.harvestedAt,
    );
  }
}
