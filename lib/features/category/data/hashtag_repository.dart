abstract class HashtagRepository {
  Stream<List<String>> getHashtagsStream();

  Future<void> addHashtag(String hashtag);

  Future<void> removeHashtag(String hashtag);
}