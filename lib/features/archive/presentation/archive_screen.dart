import 'package:flutter/material.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';

/// 보관 탭. #20에서 열매 목록 UI로 채운다. 그 전까지 자리 표시자.
class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: null,
      body: SafeArea(
        child: Center(
          child: Text('수확한 열매가 여기에 쌓여요'),
        ),
      ),
      bottomNavigationBar: MainBottomNav(currentIndex: 1),
    );
  }
}
