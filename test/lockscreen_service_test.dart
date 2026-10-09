import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:malssi/core/services/lockscreen_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('malssi/lockscreen');
  final calls = <MethodCall>[];
  var granted = true;

  setUp(() {
    calls.clear();
    granted = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'setEnabled' => granted,
        'isGranted' => granted,
        'openSettings' => true,
        _ => null,
      };
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('LockscreenService (#253)', () {
    test('setEnabled forwards the flag', () async {
      final service = LockscreenService.testWithChannel(channel);

      expect(await service.setEnabled(true), isTrue);
      expect(calls.single.method, 'setEnabled');
      expect(calls.single.arguments, {'enabled': true});

      calls.clear();
      expect(await service.setEnabled(false), isTrue);
      expect(calls.single.arguments, {'enabled': false});
    });

    test('isGranted/openSettings delegate to native', () async {
      final service = LockscreenService.testWithChannel(channel);

      expect(await service.isGranted(), isTrue);
      expect(await service.openSettings(), isTrue);
      expect(
        calls.map((c) => c.method),
        ['isGranted', 'openSettings'],
      );
    });

    test('denied permission surfaces as false', () async {
      granted = false;
      final service = LockscreenService.testWithChannel(channel);

      expect(await service.setEnabled(true), isFalse);
      expect(await service.isGranted(), isFalse);
    });

    test('missing plugin never throws (widget tests, iOS)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      final service = LockscreenService.testWithChannel(
        const MethodChannel('malssi/lockscreen-missing'),
      );

      expect(await service.setEnabled(true), isFalse);
      expect(await service.isGranted(), isFalse);
      expect(await service.openSettings(), isFalse);
    });
  });
}
