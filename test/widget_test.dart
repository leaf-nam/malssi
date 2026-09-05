import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:malssi/app.dart';
import 'package:malssi/core/theme/app_theme.dart';

void main() {
  testWidgets('AppShell shows the seed screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AppShell());
    await tester.pumpAndSettle();

    expect(find.text('말씨'), findsOneWidget);
    expect(find.text('씨앗 심기'), findsOneWidget);
  });

  testWidgets('shell keeps one bottom nav and blends color per tab (#79)',
      (WidgetTester tester) async {
    Color barColor() {
      final nav = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      return (nav.decoration as BoxDecoration).color!;
    }

    await tester.pumpWidget(const AppShell());
    await tester.pumpAndSettle();

    // 바는 셸에 1개만 상주한다.
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(barColor(), AppTheme.abyss);
    expect(find.text('씨앗 심기'), findsOneWidget);

    // 정원 탭: 바는 고정된 채 흙색으로 블렌딩되고 내용만 바뀐다.
    await tester.tap(find.text('정원'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(barColor(), AppTheme.navGardenLight);
    expect(find.text('최근 1년 · 0개의 열매'), findsOneWidget);

    // 설정 탭: 회색으로 블렌딩된다.
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(barColor(), AppTheme.navSettingsLight);
    expect(find.text('씨앗 생성 시간'), findsOneWidget);

    // 말씨 탭 복귀: 검은색으로 돌아온다.
    await tester.tap(find.text('말씨'));
    await tester.pumpAndSettle();

    expect(barColor(), AppTheme.abyss);
    expect(find.text('씨앗 심기'), findsOneWidget);
  });
}
