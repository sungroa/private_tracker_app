import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/domain/cycle_calculator.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';

void main() {
  group('CycleCalculator Tests', () {
    test('predictNextPeriod with empty logs should return today + 28 days', () {
      final logs = <CycleEvent>[];
      final prediction = CycleCalculator.predictNextPeriod(logs);
      
      final expected = DateTime.now().add(const Duration(days: 28));
      expect(prediction.year, expected.year);
      expect(prediction.month, expected.month);
      expect(prediction.day, expected.day);
    });

    test('predictNextPeriod with one log should return startDate + 28 days', () {
      final start = DateTime.utc(2026, 3, 1);
      final logs = [CycleEvent(startDate: start)];
      
      final prediction = CycleCalculator.predictNextPeriod(logs);
      expect(prediction, start.add(const Duration(days: 28)));
    });

    test('predictNextPeriod with multiple logs should use weighted average', () {
      // Cycle 1: Mar 1 to Mar 29 (28 days)
      // Cycle 2: Mar 29 to Apr 28 (30 days) - Newest
      // Weighted: (30 * 0.5 + 28 * 0.3) / (0.5 + 0.3) = 23.4 / 0.8 = 29.25 -> 29 days
      final logs = [
        CycleEvent(startDate: DateTime(2026, 4, 28)),
        CycleEvent(startDate: DateTime.utc(2026, 3, 29)),
        CycleEvent(startDate: DateTime.utc(2026, 3, 1)),
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
        CycleEvent(startDate: base.add(const Duration(days: 157))), // Day 157
        CycleEvent(startDate: base.add(const Duration(days: 129))), // Day 129 (Interval: 28)
        CycleEvent(startDate: base.add(const Duration(days: 101))), // Day 101 (Interval: 28)
        CycleEvent(startDate: base.add(const Duration(days: 56))),  // Day 56  (Interval: 45) -> Outlier
        CycleEvent(startDate: base.add(const Duration(days: 28))),  // Day 28  (Interval: 28)
        CycleEvent(startDate: base),                                // Day 0   (Interval: 28)
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
        CycleEvent(startDate: base.add(const Duration(days: 84))), // Day 84
        CycleEvent(startDate: base.add(const Duration(days: 52))), // Day 52 (Interval: 32)
        CycleEvent(startDate: base.add(const Duration(days: 24))), // Day 24 (Interval: 28)
        CycleEvent(startDate: base),                               // Day 0  (Interval: 24)
      ];
      
      final prediction = CycleCalculator.predictNextPeriod(logs);
      final latestStart = logs.first.startDate;
      
      expect(prediction, latestStart.add(const Duration(days: 29)));
    });

    test('isCurrentlyInPeriod should detect active period if no endDate', () {
      final logs = [CycleEvent(startDate: DateTime.now())];
      expect(CycleCalculator.isCurrentlyInPeriod(logs), isTrue);
    });

    test('isCurrentlyInPeriod should expire after 7 days if no endDate', () {
      final logs = [CycleEvent(startDate: DateTime.now().subtract(const Duration(days: 8)))];
      expect(CycleCalculator.isCurrentlyInPeriod(logs), isFalse);
    });

    test('predictNextPeriod with fewer than 4 intervals should skip IQR filtering', () {
      // Only 3 intervals: IQR requires >= 4, so no filtering should occur.
      // Intervals: 30, 28, 26 — all kept, weighted: (30*0.5 + 28*0.3 + 26*0.2) / 1.0 = 28.6 -> 29
      final base = DateTime(2026, 1, 1);
      final logs = [
        CycleEvent(startDate: base.add(const Duration(days: 84))), // Day 84
        CycleEvent(startDate: base.add(const Duration(days: 54))), // Day 54 (Interval: 30)
        CycleEvent(startDate: base.add(const Duration(days: 26))), // Day 26 (Interval: 28)
        CycleEvent(startDate: base),                               // Day 0  (Interval: 26)
      ];
      
      final prediction = CycleCalculator.predictNextPeriod(logs);
      final latestStart = logs.first.startDate;
      
      // Weighted: (30*0.5 + 28*0.3 + 26*0.2) / 1.0 = 15 + 8.4 + 5.2 = 28.6 -> 29
      expect(prediction, latestStart.add(const Duration(days: 29)));
    });

    test('predictNextPeriod with uniform cycles should keep all values through IQR', () {
      // 5 identical intervals of 28 days — IQR = 0, all pass filter
      final base = DateTime(2026, 1, 1);
      final logs = [
        CycleEvent(startDate: base.add(const Duration(days: 168))),
        CycleEvent(startDate: base.add(const Duration(days: 140))),
        CycleEvent(startDate: base.add(const Duration(days: 112))),
        CycleEvent(startDate: base.add(const Duration(days: 84))),
        CycleEvent(startDate: base.add(const Duration(days: 56))),
        CycleEvent(startDate: base.add(const Duration(days: 28))),
      ];
      
      final prediction = CycleCalculator.predictNextPeriod(logs);
      final latestStart = logs.first.startDate;
      
      // All intervals are 28, weighted average is 28
      expect(prediction, latestStart.add(const Duration(days: 28)));
    });

    group('Ovulation Confirmation (3-over-6 Rule)', () {
      test('confirmOvulation returns null if fewer than 9 logs', () {
        final logs = List.generate(8, (i) => SymptomLog(
          date: DateTime.utc(2026, 3, i + 1),
          symptoms: [],
          moodRating: 3,
          basalBodyTemperature: 97.0 + i * 0.1,
        ));
        expect(CycleCalculator.confirmOvulation(logs), isNull);
      });

      test('confirmOvulation detects valid shift', () {
        final logs = <SymptomLog>[];
        final baseDate = DateTime.utc(2026, 3, 1);
        for (int i = 0; i < 6; i++) {
          logs.add(SymptomLog(date: baseDate.add(Duration(days: i)), symptoms: [], moodRating: 3, basalBodyTemperature: 97.0));
        }
        for (int i = 6; i < 9; i++) {
          logs.add(SymptomLog(date: baseDate.add(Duration(days: i)), symptoms: [], moodRating: 3, basalBodyTemperature: 97.2));
        }

        final result = CycleCalculator.confirmOvulation(logs);
        expect(result, DateTime.utc(2026, 3, 6));
      });

      test('confirmOvulation handles custom threshold', () {
        final logs = <SymptomLog>[];
        final baseDate = DateTime.utc(2026, 3, 1);
        for (int i = 0; i < 6; i++) {
          logs.add(SymptomLog(date: baseDate.add(Duration(days: i)), symptoms: [], moodRating: 3, basalBodyTemperature: 36.5));
        }
        for (int i = 6; i < 9; i++) {
          logs.add(SymptomLog(date: baseDate.add(Duration(days: i)), symptoms: [], moodRating: 3, basalBodyTemperature: 36.6));
        }

        // With default 0.2, should be null
        expect(CycleCalculator.confirmOvulation(logs), isNull);
        // With 0.1, should be Mar 6
        expect(CycleCalculator.confirmOvulation(logs, threshold: 0.1), DateTime.utc(2026, 3, 6));
      });

      test('confirmOvulation prioritizes most recent shift', () {
        // Two shifts: one starting Mar 7, another starting Mar 15
        final logs = <SymptomLog>[];
        final baseDate = DateTime.utc(2026, 3, 1);
        
        // First shift (Mar 7)
        for (int i = 0; i < 6; i++) {
          logs.add(SymptomLog(date: baseDate.add(Duration(days: i)), symptoms: [], moodRating: 3, basalBodyTemperature: 97.0));
        }
        for (int i = 6; i < 9; i++) {
          logs.add(SymptomLog(date: baseDate.add(Duration(days: i)), symptoms: [], moodRating: 3, basalBodyTemperature: 97.3));
        }
        
        // Second shift (Mar 15)
        for (int i = 9; i < 14; i++) {
          logs.add(SymptomLog(date: baseDate.add(Duration(days: i)), symptoms: [], moodRating: 3, basalBodyTemperature: 97.3));
        }
        for (int i = 14; i < 17; i++) {
          logs.add(SymptomLog(date: baseDate.add(Duration(days: i)), symptoms: [], moodRating: 3, basalBodyTemperature: 97.6));
        }

        final result = CycleCalculator.confirmOvulation(logs);
        // Latest shift starts at index 14 (Mar 15). Ovulation is Mar 14.
        expect(result, DateTime.utc(2026, 3, 14));
      });

      test('confirmOvulation fails if data is missing', () {
        final logs = <SymptomLog>[];
        final baseDate = DateTime.utc(2026, 3, 1);
        for (int i = 0; i < 9; i++) {
          logs.add(SymptomLog(
            date: baseDate.add(Duration(days: i)),
            symptoms: [],
            moodRating: 3,
            basalBodyTemperature: (i == 4) ? null : 97.0 + (i >= 6 ? 0.3 : 0),
          ));
        }
        expect(CycleCalculator.confirmOvulation(logs), isNull);
      });
    });

    group('Prediction Override Tests', () {
      test('predictNextPeriod overrides using confirmed ovulation', () {
        final cycleLogs = [CycleEvent(startDate: DateTime.utc(2026, 3, 1))];
        
        // Create symptoms with a shift
        final symptoms = <SymptomLog>[];
        final baseDate = DateTime.utc(2026, 3, 1);
        for (int i = 0; i < 6; i++) {
          symptoms.add(SymptomLog(date: baseDate.add(Duration(days: i)), symptoms: [], moodRating: 3, basalBodyTemperature: 97.0));
        }
        for (int i = 6; i < 9; i++) {
          symptoms.add(SymptomLog(date: baseDate.add(Duration(days: i)), symptoms: [], moodRating: 3, basalBodyTemperature: 97.2));
        }

        // Ovulation confirmed at Mar 6. Prediction should be Mar 6 + 14 days = Mar 20.
        // Default prediction would be Mar 1 + 28 days = Mar 29.
        final prediction = CycleCalculator.predictNextPeriod(cycleLogs, symptoms);
        expect(prediction, DateTime.utc(2026, 3, 20));
      });

      test('predictNextPeriod uses default if no ovulation confirmed', () {
        final cycleLogs = [CycleEvent(startDate: DateTime.utc(2026, 3, 1))];
        final symptoms = [
          SymptomLog(date: DateTime.utc(2026, 3, 1), symptoms: [], moodRating: 3, basalBodyTemperature: 97.0),
        ];

        final prediction = CycleCalculator.predictNextPeriod(cycleLogs, symptoms);
        expect(prediction, DateTime.utc(2026, 3, 1).add(const Duration(days: 28)));
      });
    });
  });
}
