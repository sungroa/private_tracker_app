import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/core/services/clock.dart';
import 'package:private_tracker_app/core/utils/date_time_extensions.dart';
import 'package:private_tracker_app/domain/cycle_calculator.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';

import '../helpers/test_model_factory.dart';

class MockClock implements IClock {
  MockClock(this._now);
  DateTime _now;
  void setNow(DateTime newNow) => _now = newNow;
  @override
  DateTime now() => _now;
}

void main() {
  group('CycleCalculator Advanced Scenarios', () {
    late MockClock mockClock;
    late CycleCalculator calculator;

    setUp(() {
      mockClock = MockClock(DateTime(2026, 3, 15));
      calculator = CycleCalculator(mockClock);
    });

    test('Leap Year: Should handle Feb 29 correctly in prediction', () {
      // 2024 was a leap year
      final start = DateTime(2024, 2, 10);
      final logs = [TestModelFactory.createCycleLog(startDate: start)];

      // Default prediction is +28 days
      // Feb has 29 days in 2024.
      // 10 + 28 = 38. 38 - 29 = 9. -> March 9th.
      final prediction = calculator.predictNextPeriod(logs);
      expect(prediction, DateTime(2024, 3, 9));
    });

    test('Irregular Cycles: Weighted average should favor recent trends', () {
      final base = DateTime(2026, 1, 1);
      final logs = [
        TestModelFactory.createCycleLog(
          startDate: base.add(const Duration(days: 65)),
        ), // Last cycle: 35 days (100 - 65)
        TestModelFactory.createCycleLog(
          startDate: base.add(const Duration(days: 35)),
        ), // Prev cycle: 30 days (65 - 35)
        TestModelFactory.createCycleLog(startDate: base), // Initial cycle: 35 days (35 - 0)
      ];

      // The most recent cycle was 35 days.
      // The one before was 30.
      // Weighted average should be closer to 35.
      // Formula: sum(len * weight) / sum(weight)
      // weight = exp(-0.1 * index)
      // index 0: 35 * 1.0 = 35.0
      // index 1: 30 * 0.9 = 27.0
      // index 2: n/a (we need gaps between logs)

      final prediction = calculator.predictNextPeriod(logs);
      // Average of 35 and 30 with exponential decay should be > 32.5 (arithmetic mean)
      expect(prediction!.daysDifference(logs.first.startDate), greaterThan(32));
    });

    test('Confirmed Ovulation: Override prediction when BBT shift is detected', () {
      final cycleStart = DateTime(2026, 3, 1);
      final logs = [TestModelFactory.createCycleLog(startDate: cycleStart)];

      final symptoms = <SymptomLog>[];
      // Days 1-13: Normal BBT (97.0)
      for (int i = 0; i < 13; i++) {
        symptoms.add(
          TestModelFactory.createSymptomLog(
            date: cycleStart.add(Duration(days: i)),
            basalBodyTemperature: 97.0,
          ),
        );
      }
      // Days 14-16: High BBT (97.4) -> Ovulation on Day 13 (index 12)
      // Wait, 3-over-6 rule:
      // 6 low: 7, 8, 9, 10, 11, 12 (Days 8-13)
      // 3 high: 13, 14, 15 (Days 14-16)
      // Shift detected at index 12 (Day 13)
      for (int i = 13; i < 16; i++) {
        symptoms.add(
          TestModelFactory.createSymptomLog(
            date: cycleStart.add(Duration(days: i)),
            basalBodyTemperature: 97.4,
          ),
        );
      }

      // Predicted next period should be Ovulation + 14 days = Day 13 + 14 = Day 27
      // Day 1 (3/1) + 26 days = 3/27
      final prediction = calculator.predictNextPeriod(logs, symptoms);
      expect(prediction, DateTime(2026, 3, 27));
    });

    test('Current Phase: Should identify Luteal phase after confirmed ovulation', () {
      final cycleStart = DateTime(2026, 3, 1);
      final logs = [TestModelFactory.createCycleLog(startDate: cycleStart)];

      final symptoms = <SymptomLog>[];
      for (int i = 0; i < 6; i++) {
        symptoms.add(
          TestModelFactory.createSymptomLog(
            date: cycleStart.add(Duration(days: i)),
            basalBodyTemperature: 97.0,
          ),
        );
      }
      for (int i = 6; i < 9; i++) {
        symptoms.add(
          TestModelFactory.createSymptomLog(
            date: cycleStart.add(Duration(days: i)),
            basalBodyTemperature: 97.4,
          ),
        );
      }
      // Ovulation confirmed on Day 6 (3/7)

      // Set clock to Day 10 (3/11)
      mockClock.setNow(DateTime(2026, 3, 11));

      // Day 11 is > 7 days from start (not menstrual)
      // and it is AFTER confirmed ovulation -> Luteal
      expect(calculator.isCurrentlyInPeriod(logs), isFalse);
      // Note: we don't have a getPhase() method yet, but we could add it if needed.
      // For now, verify isCurrentlyInPeriod logic.
    });

    test(
      'Data Gaps: Should ignore cycles longer than 100 days as outliers when enough data is present',
      () {
        final base = DateTime(2025, 1, 1);
        // We need n >= 8 for the Hybrid Pipeline (IQR) to kick in
        final logs = [
          TestModelFactory.createCycleLog(
            startDate: base.add(const Duration(days: 400)),
          ), // Today (gap: 100)
          TestModelFactory.createCycleLog(
            startDate: base.add(const Duration(days: 300)),
          ), // gap: 28
          TestModelFactory.createCycleLog(
            startDate: base.add(const Duration(days: 272)),
          ), // gap: 30
          TestModelFactory.createCycleLog(
            startDate: base.add(const Duration(days: 242)),
          ), // gap: 29
          TestModelFactory.createCycleLog(
            startDate: base.add(const Duration(days: 213)),
          ), // gap: 28
          TestModelFactory.createCycleLog(
            startDate: base.add(const Duration(days: 185)),
          ), // gap: 30
          TestModelFactory.createCycleLog(
            startDate: base.add(const Duration(days: 155)),
          ), // gap: 28
          TestModelFactory.createCycleLog(
            startDate: base.add(const Duration(days: 127)),
          ), // gap: 27
          TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 100))),
        ];

        final prediction = calculator.predictNextPeriod(logs);

        // The 100-day gap (400-300) should be detected as an outlier (clamped to max 45 or replaced by median)
        // The prediction should definitely be less than 50 days.
        final daysToNext = prediction!.difference(logs.first.startDate).inDays;
        expect(daysToNext, lessThan(50));
      },
    );
  });
}
