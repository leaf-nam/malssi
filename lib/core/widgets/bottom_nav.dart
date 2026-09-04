import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:malssi/core/theme/app_theme.dart';

/// 3탭 내비게이션: 씨앗 / 보관 / 설정.
class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _paths = ['/', '/archive', '/settings'];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.ink900,
      selectedItemColor: AppTheme.gold,
      unselectedItemColor: AppTheme.muted,
      selectedFontSize: 9.5,
      unselectedFontSize: 9.5,
      currentIndex: currentIndex,
      onTap: (index) => context.go(_paths[index]),
      items: const [
        BottomNavigationBarItem(icon: Text('🌱'), label: '씨앗'),
        BottomNavigationBarItem(icon: Text('🧺'), label: '보관'),
        BottomNavigationBarItem(icon: Text('⚙️'), label: '설정'),
      ],
    );
  }
}
