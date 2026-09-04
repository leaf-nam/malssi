class Seed {
  final String id;
  final String dateKey;
  final String quoteId;
  final String status;
  final DateTime createdAt;

  const Seed({
    required this.id,
    required this.dateKey,
    required this.quoteId,
    required this.status,
    required this.createdAt,
  });

  /// 날짜키 (`'YYYY-MM-DD'`). 문서 ID로도 사용한다.
  static String dateKeyFor(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  bool get isLocked => status == SeedStatus.locked;
  bool get isOpened => status == SeedStatus.opened;

  factory Seed.fromMap(Map<String, dynamic> map) {
    return Seed(
      id: map['id'] ?? '',
      dateKey: map['dateKey'] ?? '',
      quoteId: map['quoteId'] ?? '',
      status: map['status'] ?? SeedStatus.locked,
      createdAt: (map['createdAt'] as dynamic).toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateKey': dateKey,
      'quoteId': quoteId,
      'status': status,
      'createdAt': createdAt,
    };
  }

  Seed copyWith({
    String? id,
    String? dateKey,
    String? quoteId,
    String? status,
    DateTime? createdAt,
  }) {
    return Seed(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      quoteId: quoteId ?? this.quoteId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// `Seed.status` 값. enum 대신 문자열 상수로 둔다 (Firestore 직렬화 단순화).
abstract class SeedStatus {
  static const locked = 'locked';
  static const opened = 'opened';
  static const expired = 'expired';
}
