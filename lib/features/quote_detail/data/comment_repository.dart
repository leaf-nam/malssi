import 'package:malssi/features/quote_detail/domain/comment.dart';

abstract class CommentRepository {
  Future<List<Comment>> getComments(String quoteId);

  /// Top 3 comments by likes (BEST).
  Future<List<Comment>> getBestComments(String quoteId);

  Future<Comment> addComment({
    required String quoteId,
    required String author,
    required String text,
  });

  Future<Comment> likeComment(String commentId);
}

/// In-memory implementation used until the Firestore backend is connected.
class InMemoryCommentRepository implements CommentRepository {
  InMemoryCommentRepository({List<Comment>? seed}) : _comments = List.of(seed ?? _defaultSeed);

  static final DateTime _base = DateTime(2026, 9, 3, 9);

  static final List<Comment> _defaultSeed = [
    Comment(
      id: 'c1',
      quoteId: 'seed-1',
      author: '민들레***',
      text: '퇴사 고민하던 요즘 딱 필요했던 말이네요. 혼자 버티지 말자고 다짐합니다.',
      likes: 41,
      createdAt: DateTime(2026, 9, 3, 8),
    ),
    Comment(
      id: 'c2',
      quoteId: 'seed-1',
      author: '산책하는곰',
      text: '팀 프로젝트 시작 전에 팀원들이랑 나눠 읽었어요.',
      likes: 33,
      createdAt: DateTime(2026, 9, 3, 6),
    ),
    Comment(
      id: 'c3',
      quoteId: 'seed-1',
      author: '겨울바다',
      text: '아이 등굣길에 같이 읽어주려고 캡처해둡니다.',
      likes: 19,
      createdAt: DateTime(2026, 9, 3, 4),
    ),
    Comment(
      id: 'c4',
      quoteId: 'seed-1',
      author: '라이트하우스',
      text: '오늘따라 유독 와닿네요.',
      likes: 2,
      createdAt: _base,
    ),
  ];

  final List<Comment> _comments;

  @override
  Future<List<Comment>> getComments(String quoteId) async {
    final list = _comments.where((c) => c.quoteId == quoteId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<Comment>> getBestComments(String quoteId) async {
    final list = _comments.where((c) => c.quoteId == quoteId).toList()
      ..sort((a, b) => b.likes.compareTo(a.likes));
    return list.take(3).toList();
  }

  @override
  Future<Comment> addComment({
    required String quoteId,
    required String author,
    required String text,
  }) async {
    final comment = Comment(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      quoteId: quoteId,
      author: author,
      text: text,
      likes: 0,
      createdAt: DateTime.now(),
    );
    _comments.add(comment);
    return comment;
  }

  @override
  Future<Comment> likeComment(String commentId) async {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) {
      throw StateError('Comment not found: $commentId');
    }
    final updated = _comments[index].copyWith(likes: _comments[index].likes + 1);
    _comments[index] = updated;
    return updated;
  }
}
