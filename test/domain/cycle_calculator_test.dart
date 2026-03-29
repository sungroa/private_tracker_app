import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/domain/cycle_calculator.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';

void main() {
  group('CycleCalculator Tests', () {
    test('predictNextPeriod with empty logs should return today + 28 days', () {
      final logs = <CycleLog>[];
      final prediction = CycleCalculator.predictNextPeriod(logs);
      
      final expected = DateTime.now().add(const Duration(days: 28));
      expect(prediction.year, expected.year);
      expect(prediction.month, expected.month);
      expect(prediction.day, expected.day);
    });

    test('predictNextPeriod with one log should return startDate + 28 days', () {
      final start = DateTime(2026, 3, 1);
      final logs = [CycleLog(startDate: start)];
      
      final prediction = CycleCalculator.predictNextPeriod(logs);
      expect(prediction, start.add(const Duration(days: 28)));
    });

    test('predictNextPeriod with multiple logs should use weighted average', () {
      // Cycle 1: Mar 1 to Mar 29 (28 days)
      // Cycle 2: Mar 29 to Apr 28 (30 days) - Newest
      // Weighted: (30 * 0.5 + 28 * 0.3) / (0.5 + 0.3) = 23.4 / 0.8 = 29.25 -> 29 days
      final logs = [
        CycleLog(startDate: DateTime(2026, 4, 28)),
        CycleLog(startDate: DateTime(2026, 3, 29)),
        CycleLog(startDate: DateTime(2026, 3, 1)),
      ];
      
      final prediction = CycleCalculator.predictNextPeriod(logs);
      
      // Latest start (Apr 28) + 29 days = May 27
      expect(prediction, DateTime(2026, 4, 28).add(const Duration(days: 29)));
    });

    test('predictNextPeriod should filter outliers with IQR', () {
      // 5 intervals: 28, 28, 45, 28, 28
      // 45 is a significant outlier that should be rejected by IQR
      final base = DateTime(2026, 1, 1);
      final logs = [
        CycleLog(startDate: base.add(const Duration(days: 157))), // Day 157
        CycleLog(startDate: base.add(const Duration(days: 129))), // Day 129 (Interval: 28)
        CycleLog(startDate: base.add(const Duration(days: 101))), // Day 101 (Interval: 28)
        CycleLog(startDate: base.add(const Duration(days: 56))),  // Day 56  (Interval: 45) -> Outlier
        CycleLog(startDate: base.add(const Duration(days: 28))),  // Day 28  (Interval: 28)
        CycleLog(startDate: base),                                // Day 0   (Interval: 28)
      ];
      
      final prediction = CycleCalculator.predictNextPeriod(logs);
      final latestStart = logs.first.startDate;
      
      // Should ignore 45 and use 28
      expect(prediction, latestStart.add(const Duration(days: 28)));
    });

    test('predictNextPeriod should apply decaying weights (50/30/20)', () {
      // 3 intervals: 32 (newest), 28, 24
      // Weighted: (32*0.5 + 28*0.3 + 24*0.2) / (0.5+0.3+0.2) = 16 + 8.4 + 4.8 = 29.2 -> 29
      final base = DateTime(2026, 1, 1);
      final logs = [
        CycleLog(startDate: base.add(const Duration(days: 84))), // Day 84
        CycleLog(startDate: base.add(const Duration(days: 52))), // Day 52 (Interval: 32)
        CycleLog(startDate: base.add(const Duration(days: 24))), // Day 24 (Interval: 28)
        CycleLog(startDate: base),                               // Day 0  (Interval: 24)
      ];
      
      final prediction = CycleCalculator.predictNextPeriod(logs);
      final latestStart = logs.first.startDate;
      
      expect(prediction, latestStart.add(const Duration(days: 29)));
    });

    test('isCurrentlyInPeriod should detect active period if no endDate', () {
      final logs = [CycleLog(startDate: DateTime.now())];
      expect(CycleCalculator.isCurrentlyInPeriod(logs), isTrue);
    });

    test('isCurrentlyInPeriod should expire after 7 days if no endDate', () {
      final logs = [CycleLog(startDate: DateTime.now().subtract(const Duration(days: 8)))];
      expect(CycleCalculator.isCurrentlyInPeriod(logs), isFalse);
    });
  });
}
