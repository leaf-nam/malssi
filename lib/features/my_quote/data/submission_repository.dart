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