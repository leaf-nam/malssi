import 'package:flutter/foundation.dart';
import 'package:malssi/features/quote_detail/data/comment_repository.dart';
import 'package:malssi/features/quote_detail/domain/comment.dart';

/// Minimal [ChangeNotifier]-based state for the quote-detail screen.
class CommentProvider extends ChangeNotifier {
  CommentProvider({required this._repository});

  final CommentRepository _repository;

  String _quoteId = '';
  String get quoteId => _quoteId;

  List<Comment> _best = const [];
  List<Comment> get best => _best;

  List<Comment> _recent = const [];
  List<Comment> get recent => _recent;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> load(String quoteId) async {
    _quoteId = quoteId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _best = await _repository.getBestComments(quoteId);
      _recent = await _repository.getComments(quoteId);
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addComment(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _repository.addComment(
        quoteId: _quoteId,
        author: '나',
        text: text.trim(),
      );
      await load(_quoteId);
    } catch (e) {
      _errorMessage = '$e';
      notifyListeners();
    }
  }

  Future<void> likeComment(String commentId) async {
    try {
      await _repository.likeComment(commentId);
      await load(_quoteId);
    } catch (e) {
      _errorMessage = '$e';
      notifyListeners();
    }
  }
}
