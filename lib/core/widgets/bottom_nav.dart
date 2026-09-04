import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 3탭 내비게이션: 말씨 / 정원 / 설정.
/// 색상은 테마(`bottomNavigationBarTheme`)를 따르므로 모드를 자동 추종한다.
class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _paths = ['/', '/archive', '/settings'];

  @override
  Widget build(BuildContext context) {
    // #60: 바·글씨·아이콘 확대. 상단 패딩으로 전체 높이를 키운다.
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        iconSize: 30,
        selectedFontSize: 12.5,
        unselectedFontSize: 12.5,
        currentIndex: currentIndex,
        onTap: (index) => context.go(_paths[index]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.eco), label: '말씨'),
          BottomNavigationBarItem(icon: Icon(Icons.grass), label: '정원'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
