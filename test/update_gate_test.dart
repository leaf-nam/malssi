import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';

import 'package:malssi/core/widgets/update_gate.dart';

void main() {
  group('MalssiUpgraderMessages (#192)', () {
    MalssiUpgraderMessages messages() => MalssiUpgraderMessages();

    test('shows Korean copy', () {
      expect(messages().message(UpgraderMessage.title), '업데이트 안내');
      expect(messages().message(UpgraderMessage.buttonTitleUpdate),
          '지금 업데이트');
      expect(messages().message(UpgraderMessage.buttonTitleLater), '나중에');
      expect(messages().message(UpgraderMessage.buttonTitleIgnore),
          '무시하기');
      expect(messages().message(UpgraderMessage.body),
          contains('새 버전이 있어요'));
    });
  });

  group('UpdateGate (#192)', () {
    testWidgets('disabled passes the child through', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UpdateGate(
            enabled: false,
            child: Text('본문'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('본문'), findsOneWidget);
      expect(find.byType(UpgradeAlert), findsNothing);
    });

    // enabled 경로는 스토어 조회를 시작해 테스트 타이머가 남으므로,
    // 위젯 펌프 대신 실기기에서 검증한다.
  });
}
