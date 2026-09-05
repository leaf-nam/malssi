import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:malssi/core/theme/app_theme.dart';

/// 3탭 내비게이션: 말씨 / 정원 / 설정.
/// 색상은 테마(`bottomNavigationBarTheme`)를 따르므로 모드를 자동 추종한다.
/// 바 배경은 탭별·모드별로 다르다 (#75): 말씨=배경과 동일한 검은색,
/// 정원=흙색, 설정=회색.
class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _paths = ['/', '/archive', '/settings'];

  /// 탭 인덱스 + 밝기별 바 배경색.
  static Color backgroundFor(int index, Brightness brightness) {
    final light = brightness == Brightness.light;
    switch (index) {
      case 0:
        return AppTheme.abyss;
      case 1:
        return light ? AppTheme.navGardenLight : AppTheme.navGardenDark;
      default:
        return light
            ? AppTheme.navSettingsLight
            : AppTheme.navSettingsDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    // #60: 바·글씨·아이콘 확대. 상단 패딩으로 전체 높이를 키운다.
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: backgroundFor(
            currentIndex, Theme.of(context).brightness),
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
