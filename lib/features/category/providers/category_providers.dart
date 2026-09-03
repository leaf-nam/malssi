import 'package:flutter/foundation.dart';
import 'package:malssi/features/category/data/hashtag_repository.dart';

/// Minimal [ChangeNotifier]-based state for the category screen.
class CategoryProvider extends ChangeNotifier {
  CategoryProvider({required this._repository});

  final HashtagCountRepository _repository;

  List<HashtagCount> _tags = const [];
  List<HashtagCount> get tags => _tags;

  /// Top 4 tags shown as the grid.
  List<HashtagCount> get topTags => _tags.take(4).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tags = await _repository.getHashtagCounts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
