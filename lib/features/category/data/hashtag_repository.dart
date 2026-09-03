abstract class HashtagRepository {
  Stream<List<String>> getHashtagsStream();

  Future<void> addHashtag(String hashtag);

  Future<void> removeHashtag(String hashtag);
}

/// Tag with its quote count, used by the category screen.
class HashtagCount {
  const HashtagCount({required this.name, required this.count});

  final String name;
  final int count;
}

abstract class HashtagCountRepository {
  Future<List<HashtagCount>> getHashtagCounts();
}

/// In-memory implementation used until the Firestore backend is connected.
class InMemoryHashtagRepository implements HashtagRepository, HashtagCountRepository {
  InMemoryHashtagRepository({Map<String, int>? seed}) : _counts = Map.of(seed ?? _defaultSeed);

  static const Map<String, int> _defaultSeed = {
    '위로': 312,
    '도전': 204,
    '사랑': 189,
    '성장': 167,
    '협력': 92,
    '관계': 88,
    '인내': 75,
    '자존감': 61,
    '가족': 54,
  };

  final Map<String, int> _counts;

  @override
  Stream<List<String>> getHashtagsStream() => Stream.value(_counts.keys.toList());

  @override
  Future<void> addHashtag(String hashtag) async {
    _counts.update(hashtag, (c) => c + 1, ifAbsent: () => 1);
  }

  @override
  Future<void> removeHashtag(String hashtag) async {
    _counts.remove(hashtag);
  }

  @override
  Future<List<HashtagCount>> getHashtagCounts() async {
    final list = _counts.entries
        .map((e) => HashtagCount(name: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list;
  }
}
