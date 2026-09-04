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
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 9.5,
      unselectedFontSize: 9.5,
      currentIndex: currentIndex,
      onTap: (index) => context.go(_paths[index]),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.eco), label: '말씨'),
        BottomNavigationBarItem(icon: Icon(Icons.grass), label: '정원'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
      ],
    );
  }
}
