import 'package:flutter/material.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';

/// 설정 탭. #21에서 씨앗 생성시간 설정 UI로 채운다. 그 전까지 자리 표시자.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: null,
      body: SafeArea(
        child: Center(
          child: Text('씨앗 생성시간을 여기에 설정해요'),
        ),
      ),
      bottomNavigationBar: MainBottomNav(currentIndex: 2),
    );
  }
}
