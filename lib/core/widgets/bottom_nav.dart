import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:malssi/core/theme/app_theme.dart';

/// Shared bottom navigation matching the MVP mockup:
/// 홈 / 카테고리 / 명언 쓰기 / 좋아요 / 마이
/// (#19에서 제거 예정. 신규 화면은 [MainBottomNav]를 사용한다.)
class MvpBottomNav extends StatelessWidget {
  const MvpBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _paths = ['/', '/category', '/write', '/liked', '/mypage'];

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
        BottomNavigationBarItem(icon: Text('홈'), label: '홈'),
        BottomNavigationBarItem(icon: Text('태그'), label: '카테고리'),
        BottomNavigationBarItem(icon: Text('✒'), label: '명언 쓰기'),
        BottomNavigationBarItem(icon: Text('♥'), label: '좋아요'),
        BottomNavigationBarItem(icon: Text('☺'), label: '마이'),
      ],
    );
  }
}

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
