import 'package:flutter/foundation.dart';
import 'package:malssi/features/my_quote/data/submission_repository.dart';

/// Minimal [ChangeNotifier]-based state for the write screen.
class WriteProvider extends ChangeNotifier {
  WriteProvider({required this._repository});

  final TypedSubmissionRepository _repository;

  List<Submission> _mine = const [];
  List<Submission> get mine => _mine;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    try {
      _mine = await _repository.getMySubmissions();
      notifyListeners();
    } catch (e) {
      _errorMessage = '$e';
      notifyListeners();
    }
  }

  Future<bool> submit({required String text, required String author, required String category}) async {
    if (text.trim().isEmpty) return false;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.submitQuote(
        text: text.trim(),
        author: author.trim().isEmpty ? '본인' : author.trim(),
        category: category,
      );
      await load();
      return true;
    } catch (e) {
      _errorMessage = '$e';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
