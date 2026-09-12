import 'package:flutter_test/flutter_test.dart';

import 'package:malssi/core/services/debug_clock.dart';

void main() {
  tearDown(DebugClock.reset);

  group('DebugClock', () {
    test('starts unshifted at real time', () {
      expect(DebugClock.offset, Duration.zero);
      expect(DebugClock.isShifted, isFalse);
      expect(
        DebugClock.now().difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('offset accumulates shifts for display', () {
      DebugClock.shift(const Duration(hours: 1));
      expect(DebugClock.offset, const Duration(hours: 1));
      expect(DebugClock.isShifted, isTrue);

      DebugClock.shift(const Duration(days: 1));
      expect(DebugClock.offset, const Duration(hours: 25));
    });

    test('reset clears the offset', () {
      DebugClock.shift(const Duration(hours: 3));
      DebugClock.reset();

      expect(DebugClock.offset, Duration.zero);
      expect(DebugClock.isShifted, isFalse);
    });
  });
}
