class Fruit {
  final String id;
  final String seedId;
  final String quoteId;
  final String text;
  final String author;
  final DateTime harvestedAt;

  /// 수확 시점의 테마 스냅샷 (`SeedTheme` 값 중 1개, 미분류는 `''`).
  final String theme;

  /// 그날의 후기. 미작성은 `''`.
  final String memo;

  /// 그날의 점수 (0~5, `0` = 미평가).
  final int fidelityScore;

  const Fruit({
    required this.id,
    required this.seedId,
    required this.quoteId,
    required this.text,
    required this.author,
    required this.harvestedAt,
    this.theme = '',
    this.memo = '',
    this.fidelityScore = 0,
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
      memo: map['memo'] ?? '',
      fidelityScore: map['fidelityScore'] ?? 0,
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
      'memo': memo,
      'fidelityScore': fidelityScore,
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
    String? memo,
    int? fidelityScore,
  }) {
    return Fruit(
      id: id ?? this.id,
      seedId: seedId ?? this.seedId,
      quoteId: quoteId ?? this.quoteId,
      text: text ?? this.text,
      author: author ?? this.author,
      harvestedAt: harvestedAt ?? this.harvestedAt,
      theme: theme ?? this.theme,
      memo: memo ?? this.memo,
      fidelityScore: fidelityScore ?? this.fidelityScore,
    );
  }

  /// 수확일 날짜키 (`'YYYY-MM-DD'`). 잔디 그리드의 칸 키로 사용한다.
  String get harvestDateKey {
    final m = harvestedAt.month.toString().padLeft(2, '0');
    final d = harvestedAt.day.toString().padLeft(2, '0');
    return '${harvestedAt.year}-$m-$d';
  }

  /// 후기 작성 여부. 잔디는 후기를 남긴 열매만 심어진다 (#65).
  /// 별점(1~5) 또는 한줄 후기 둘 중 하나라도 있으면 작성됨으로 본다.
  bool get isReviewed => memo.isNotEmpty || fidelityScore > 0;
}
