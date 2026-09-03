import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/features/mypage/providers/user_providers.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userAsync = context.watch<UserProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
      ),
      body: Center(
        child: userAsync.when(
          data: (profile) => _buildProfile(profile),
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildProfile(Map<String, dynamic> profile) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.indigo,
          child: Icon(Icons.person, color: Colors.white, size: 50),
        ),
        const SizedBox(height: 20),
        Text(
          profile['displayName'] ?? '내 이름',
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 10),
        Text(
          profile['email'] ?? '이메일 없음',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: () {
            // Handle sign out or profile edit
          },
          icon: const Icon(Icons.logout),
          label: const Text('로그아웃'),
        ),
      ],
    );
  }
}