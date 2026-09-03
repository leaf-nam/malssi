abstract class UserRepository {
  Future<Map<String, dynamic>> getUserProfile();

  Stream<Map<String, dynamic>> getUserProfileStream();

  Future<void> updateUserProfile({
    required String displayName,
    required String? profileImageUrl,
  });

  Future<void> deleteAccount();
}