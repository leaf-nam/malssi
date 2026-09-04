import 'package:flutter_test/flutter_test.dart';

import 'package:malssi/app.dart';

void main() {
  testWidgets('AppShell shows the seed screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AppShell());
    await tester.pumpAndSettle();

    expect(find.text('오늘의 씨앗'), findsOneWidget);
    expect(find.text('씨앗 심기'), findsOneWidget);
  });
}
