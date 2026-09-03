class DummyAuthService {
  Future<void> signInAnonymously() async {
    // Simulate anonymous sign-in
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> signInWithGoogle() async {
    // Simulate Google sign-in
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> signOut() async {
    // Simulate sign-out
    await Future.delayed(const Duration(milliseconds: 500));
  }

  String? get currentUserId => 'anonymous_user';
}