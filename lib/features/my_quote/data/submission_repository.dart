/// Submission review status shown in the write screen.
enum SubmissionStatus { pending, approved, rejected }

extension SubmissionStatusLabel on SubmissionStatus {
  String get label {
    switch (this) {
      case SubmissionStatus.pending:
        return '심사중';
      case SubmissionStatus.approved:
        return '승인됨';
      case SubmissionStatus.rejected:
        return '반려됨';
    }
  }
}

class Submission {
  const Submission({
    required this.id,
    required this.text,
    required this.author,
    required this.category,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String author;
  final String category;
  final SubmissionStatus status;
  final DateTime createdAt;
}

abstract class SubmissionRepository {
  Future<void> submitQuote({
    required String text,
    required String author,
    required String category,
  });

  Stream<List<Map<String, dynamic>>> getSubmissionsStream();

  Future<void> updateSubmissionStatus({
    required String submissionId,
    required String status,
  });
}

/// Typed helpers on top of the legacy map-based API.
abstract class TypedSubmissionRepository extends SubmissionRepository {
  Future<List<Submission>> getMySubmissions();
}

/// In-memory implementation used until the Firestore backend is connected.
class InMemorySubmissionRepository implements TypedSubmissionRepository {
  InMemorySubmissionRepository({List<Submission>? seed})
      : _submissions = List.of(seed ?? _defaultSeed);

  static final List<Submission> _defaultSeed = [
    Submission(
      id: 's1',
      text: '넘어진 김에 쉬어가도 괜찮다.',
      author: '본인',
      category: '위로',
      status: SubmissionStatus.pending,
      createdAt: DateTime(2026, 9, 2),
    ),
    Submission(
      id: 's2',
      text: '오늘 걷지 않으면 내일은 뛰어야 한다.',
      author: '본인',
      category: '도전',
      status: SubmissionStatus.approved,
      createdAt: DateTime(2026, 8, 28),
    ),
    Submission(
      id: 's3',
      text: '괜찮아, 다음이 있잖아.',
      author: '본인',
      category: '위로',
      status: SubmissionStatus.rejected,
      createdAt: DateTime(2026, 8, 20),
    ),
  ];

  final List<Submission> _submissions;

  @override
  Future<void> submitQuote({
    required String text,
    required String author,
    required String category,
  }) async {
    _submissions.insert(
      0,
      Submission(
        id: 's${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        author: author,
        category: category,
        status: SubmissionStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
  }

  Map<String, dynamic> _toMap(Submission s) => {
        'id': s.id,
        'text': s.text,
        'author': s.author,
        'category': s.category,
        'status': s.status.name,
        'createdAt': s.createdAt,
      };

  @override
  Stream<List<Map<String, dynamic>>> getSubmissionsStream() =>
      Stream.value(_submissions.map(_toMap).toList());

  @override
  Future<void> updateSubmissionStatus({
    required String submissionId,
    required String status,
  }) async {
    final parsed = SubmissionStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => SubmissionStatus.pending,
    );
    final index = _submissions.indexWhere((s) => s.id == submissionId);
    if (index == -1) {
      throw StateError('Submission not found: $submissionId');
    }
    final old = _submissions[index];
    _submissions[index] = Submission(
      id: old.id,
      text: old.text,
      author: old.author,
      category: old.category,
      status: parsed,
      createdAt: old.createdAt,
    );
  }

  @override
  Future<List<Submission>> getMySubmissions() async => List.unmodifiable(_submissions);
}
