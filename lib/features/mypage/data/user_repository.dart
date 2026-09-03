abstract class UserRepository {
  Future<Map<String, dynamic>> getUserProfile();

  Stream<Map<String, dynamic>> getUserProfileStream();

  Future<void> updateUserProfile({
    required String displayName,
    required String? profileImageUrl,
  });

  Future<void> deleteAccount();
}

/// In-memory implementation used until Firebase Auth is connected.
class DummyUserRepository implements UserRepository {
  Map<String, dynamic> _profile = {
    'displayName': '게스트',
    'email': 'guest@example.com',
    'profileImageUrl': null,
  };

  @override
  Future<Map<String, dynamic>> getUserProfile() async => Map.of(_profile);

  @override
  Stream<Map<String, dynamic>> getUserProfileStream() => Stream.value(Map.of(_profile));

  @override
  Future<void> updateUserProfile({
    required String displayName,
    required String? profileImageUrl,
  }) async {
    _profile = {
      ..._profile,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
    };
  }

  @override
  Future<void> deleteAccount() async {
    _profile = {};
  }
}
