import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/core/services/clock.dart';
import 'package:private_tracker_app/domain/cycle_calculator.dart';

import '../helpers/test_model_factory.dart';

/// A mock clock for deterministic testing.
class MockClock implements IClock {
  MockClock(this._now);
  DateTime _now;

  void setNow(DateTime newNow) => _now = newNow;

  @override
  DateTime now() => _now;
}

void main() {
  group('CycleCalculator Clock-Dependent Tests', () {
    late MockClock mockClock;
    late CycleCalculator calculator;

    setUp(() {
      // Fixed "now" for deterministic tests
      mockClock = MockClock(DateTime(2026, 3, 15, 10, 0, 0));
      calculator = CycleCalculator(mockClock);
    });

    test('isCurrentlyInPeriod should be true if today is within 7 days of start', () {
      final start = DateTime(2026, 3, 10); // 5 days ago relative to mockClock
      final logs = [TestModelFactory.createCycleLog(startDate: start)];

      expect(calculator.isCurrentlyInPeriod(logs), isTrue);
    });

    test('isCurrentlyInPeriod should be false if today is 8 days after start', () {
      final start = DateTime(2026, 3, 7); // 8 days ago relative to mockClock
      final logs = [TestModelFactory.createCycleLog(startDate: start)];

      expect(calculator.isCurrentlyInPeriod(logs), isFalse);
    });

    test('currentCycleDay should return 1 if start date is today', () {
      final start = DateTime(2026, 3, 15);
      expect(calculator.currentCycleDay(start), 1);
    });

    test('currentCycleDay should return 6 if start date was 5 days ago', () {
      final start = DateTime(2026, 3, 10);
      expect(calculator.currentCycleDay(start), 6);
    });

    test('isCurrentlyInPeriod should handle month boundary correctly', () {
      // Set clock to beginning of next month
      mockClock.setNow(DateTime(2026, 4, 2));

      // Period started at end of previous month
      final start = DateTime(2026, 3, 29);
      final logs = [TestModelFactory.createCycleLog(startDate: start)];

      // 3/29, 3/30, 3/31, 4/1, 4/2 (5th day) -> Should be true
      expect(calculator.isCurrentlyInPeriod(logs), isTrue);

      // Move clock forward
      mockClock.setNow(DateTime(2026, 4, 6)); // 8th day
      expect(calculator.isCurrentlyInPeriod(logs), isFalse);
    });
  });
}
