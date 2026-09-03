import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:malssi/features/auth/data/dummy_auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = DummyAuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Flutter App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                await authService.signInAnonymously();
                if (!context.mounted) return;
                context.go('/home');
              },
              icon: const Icon(Icons.person_add),
              label: const Text('익명 로그인'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await authService.signInWithGoogle();
                if (!context.mounted) return;
                context.go('/home');
              },
              icon: const Icon(Icons.gesture),
              label: const Text('Google으로 계속하기'),
            ),
          ],
        ),
      ),
    );
  }
}
