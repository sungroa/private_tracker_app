import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/core/services/clock.dart';
import 'package:private_tracker_app/domain/cycle_calculator.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';

import '../helpers/test_model_factory.dart';

void main() {
  late CycleCalculator calculator;

  setUp(() {
    calculator = CycleCalculator(SystemClock());
  });

  group('CycleCalculator Tests', () {
    test('predictNextPeriod with empty logs should return null', () {
      final prediction = calculator.predictNextPeriod([]);
      expect(prediction, isNull);
    });

    test('predictNextPeriod with one log should return startDate + 28 days', () {
      final start = DateTime.utc(2026, 3, 1);
      final logs = [TestModelFactory.createCycleLog(startDate: start)];

      final prediction = calculator.predictNextPeriod(logs);
      expect(prediction, start.add(const Duration(days: 28)));
    });

    test('predictNextPeriod with multiple logs should use weighted average', () {
      final logs = [
        TestModelFactory.createCycleLog(startDate: DateTime.utc(2026, 4, 28)),
        TestModelFactory.createCycleLog(startDate: DateTime.utc(2026, 3, 29)),
        TestModelFactory.createCycleLog(startDate: DateTime.utc(2026, 3, 1)),
      ];

      final prediction = calculator.predictNextPeriod(logs);
      expect(prediction, DateTime.utc(2026, 4, 28).add(const Duration(days: 29)));
    });

    test('predictNextPeriod should filter outliers with IQR', () {
      final base = DateTime.utc(2026, 1, 1);
      final logs = [
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 157))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 129))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 101))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 56))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 28))),
        TestModelFactory.createCycleLog(startDate: base),
      ];

      final prediction = calculator.predictNextPeriod(logs);
      expect(prediction, logs.first.startDate.add(const Duration(days: 28)));
    });

    test('predictNextPeriod should apply exponential decay weights', () {
      final base = DateTime.utc(2026, 1, 1);
      final logs = [
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 84))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 52))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 24))),
        TestModelFactory.createCycleLog(startDate: base),
      ];

      final prediction = calculator.predictNextPeriod(logs);
      expect(prediction, logs.first.startDate.add(const Duration(days: 28)));
    });

    test('isCurrentlyInPeriod should detect active period if no endDate', () {
      final logs = [TestModelFactory.createCycleLog(startDate: DateTime.now())];
      expect(calculator.isCurrentlyInPeriod(logs), isTrue);
    });

    test('isCurrentlyInPeriod should expire after 7 days if no endDate', () {
      final logs = [
        TestModelFactory.createCycleLog(
          startDate: DateTime.now().subtract(const Duration(days: 8)),
        ),
      ];
      expect(calculator.isCurrentlyInPeriod(logs), isFalse);
    });

    test('predictNextPeriod with uniform cycles should keep all values through IQR', () {
      final base = DateTime.utc(2026, 1, 1);
      final logs = [
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 168))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 140))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 112))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 84))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 56))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 28))),
      ];

      final prediction = calculator.predictNextPeriod(logs);
      expect(prediction, logs.first.startDate.add(const Duration(days: 28)));
    });

    group('Ovulation Confirmation (3-over-6 Rule)', () {
      test('confirmOvulation returns null if fewer than 9 logs', () {
        final logs = List.generate(
          8,
          (i) => TestModelFactory.createSymptomLog(
            date: DateTime.utc(2026, 3, i + 1),
            basalBodyTemperature: 97.0 + i * 0.1,
          ),
        );
        expect(calculator.confirmOvulation(logs), isNull);
      });

      test('confirmOvulation detects valid shift', () {
        final logs = <SymptomLog>[];
        final baseDate = DateTime.utc(2026, 3, 1);
        for (int i = 0; i < 6; i++) {
          logs.add(
            TestModelFactory.createSymptomLog(
              date: baseDate.add(Duration(days: i)),
              basalBodyTemperature: 97.0,
            ),
          );
        }
        for (int i = 6; i < 9; i++) {
          logs.add(
            TestModelFactory.createSymptomLog(
              date: baseDate.add(Duration(days: i)),
              basalBodyTemperature: 97.2,
            ),
          );
        }

        final result = calculator.confirmOvulation(logs);
        expect(result, DateTime.utc(2026, 3, 6));
      });

      test('confirmOvulation prioritizes most recent shift', () {
        final logs = <SymptomLog>[];
        final baseDate = DateTime.utc(2026, 3, 1);

        for (int i = 0; i < 6; i++) {
          logs.add(
            TestModelFactory.createSymptomLog(
              date: baseDate.add(Duration(days: i)),
              basalBodyTemperature: 97.0,
            ),
          );
        }
        for (int i = 6; i < 9; i++) {
          logs.add(
            TestModelFactory.createSymptomLog(
              date: baseDate.add(Duration(days: i)),
              basalBodyTemperature: 97.3,
            ),
          );
        }

        for (int i = 9; i < 14; i++) {
          logs.add(
            TestModelFactory.createSymptomLog(
              date: baseDate.add(Duration(days: i)),
              basalBodyTemperature: 97.3,
            ),
          );
        }
        for (int i = 14; i < 17; i++) {
          logs.add(
            TestModelFactory.createSymptomLog(
              date: baseDate.add(Duration(days: i)),
              basalBodyTemperature: 97.6,
            ),
          );
        }

        final result = calculator.confirmOvulation(logs);
        expect(result, DateTime.utc(2026, 3, 14));
      });

      test('confirmOvulation fails if data is missing', () {
        final logs = <SymptomLog>[];
        final baseDate = DateTime.utc(2026, 3, 1);
        for (int i = 0; i < 9; i++) {
          logs.add(
            TestModelFactory.createSymptomLog(
              date: baseDate.add(Duration(days: i)),
              basalBodyTemperature: (i == 4) ? null : 97.0 + (i >= 6 ? 0.3 : 0),
            ),
          );
        }
        expect(calculator.confirmOvulation(logs), isNull);
      });
    });

    group('Prediction Override Tests', () {
      test('predictNextPeriod overrides using confirmed ovulation', () {
        final cycleLogs = [TestModelFactory.createCycleLog(startDate: DateTime.utc(2026, 3, 1))];

        final symptoms = <SymptomLog>[];
        final baseDate = DateTime.utc(2026, 3, 1);
        for (int i = 0; i < 6; i++) {
          symptoms.add(
            TestModelFactory.createSymptomLog(
              date: baseDate.add(Duration(days: i)),
              basalBodyTemperature: 97.0,
            ),
          );
        }
        for (int i = 6; i < 9; i++) {
          symptoms.add(
            TestModelFactory.createSymptomLog(
              date: baseDate.add(Duration(days: i)),
              basalBodyTemperature: 97.2,
            ),
          );
        }

        final prediction = calculator.predictNextPeriod(cycleLogs, symptoms);
        expect(prediction, DateTime.utc(2026, 3, 20));
      });

      test('predictNextPeriod uses default if no ovulation confirmed', () {
        final cycleLogs = [TestModelFactory.createCycleLog(startDate: DateTime.utc(2026, 3, 1))];
        final symptoms = [
          TestModelFactory.createSymptomLog(
            date: DateTime.utc(2026, 3, 1),
            basalBodyTemperature: 97.0,
          ),
        ];

        final prediction = calculator.predictNextPeriod(cycleLogs, symptoms);
        expect(prediction, DateTime.utc(2026, 3, 1).add(const Duration(days: 28)));
      });
    });

    group('Multi-Cycle Projection (predictFuturePeriods)', () {
      test('returns empty list for empty cycle logs', () {
        final result = calculator.predictFuturePeriods([]);
        expect(result, isEmpty);
      });

      test('cold start: 1 recorded cycle → 1 projection', () {
        final logs = [TestModelFactory.createCycleLog(startDate: DateTime.utc(2026, 3, 1))];
        // 0 historical lengths → adaptive count = 1
        final result = calculator.predictFuturePeriods(logs);
        expect(result.length, 1);
        expect(result.first, DateTime.utc(2026, 3, 1).add(const Duration(days: 28)));
      });

      test('tier 2: 3 recorded cycles → 2 projections', () {
        // 2 valid historical lengths (3 cycles = 2 intervals)
        final base = DateTime.utc(2026, 1, 1);
        final logs = [
          TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 56))),
          TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 28))),
          TestModelFactory.createCycleLog(startDate: base),
        ];
        final result = calculator.predictFuturePeriods(logs);
        expect(result.length, 2);
      });

      test('tier 3: 5 recorded cycles → 3 projections', () {
        // 4 valid historical lengths (5 cycles = 4 intervals)
        final base = DateTime.utc(2026, 1, 1);
        final logs = List.generate(
          5,
          (i) => TestModelFactory.createCycleLog(startDate: base.add(Duration(days: i * 28))),
        ).reversed.toList(); // newest first input
        final result = calculator.predictFuturePeriods(logs);
        expect(result.length, 3);
      });

      test('tier 4: 9 recorded cycles → 4 projections', () {
        // 8 valid historical lengths (9 cycles = 8 intervals)
        final base = DateTime.utc(2026, 1, 1);
        final logs = List.generate(
          9,
          (i) => TestModelFactory.createCycleLog(startDate: base.add(Duration(days: i * 28))),
        ).reversed.toList();
        final result = calculator.predictFuturePeriods(logs);
        expect(result.length, 4);
      });

      test('projections are in chronological order (each after the previous)', () {
        final base = DateTime.utc(2026, 1, 1);
        final logs = List.generate(
          9,
          (i) => TestModelFactory.createCycleLog(startDate: base.add(Duration(days: i * 28))),
        ).reversed.toList();
        final result = calculator.predictFuturePeriods(logs);
        for (int i = 1; i < result.length; i++) {
          expect(
            result[i].isAfter(result[i - 1]),
            isTrue,
            reason: 'Projection $i must be after projection ${i - 1}',
          );
        }
      });

      test('explicit count overrides adaptive tier', () {
        // Enough history for tier 4, but we explicitly request 2
        final base = DateTime.utc(2026, 1, 1);
        final logs = List.generate(
          9,
          (i) => TestModelFactory.createCycleLog(startDate: base.add(Duration(days: i * 28))),
        ).reversed.toList();
        final result = calculator.predictFuturePeriods(logs, count: 2);
        expect(result.length, 2);
      });

      test('STM override applies only to first projection; subsequent use statistical model', () {
        // Single-cycle logs + 9 BBT readings confirming ovulation on day 6
        final cycleStart = DateTime.utc(2026, 3, 1);
        final cycleLogs = [TestModelFactory.createCycleLog(startDate: cycleStart)];

        final symptoms = <dynamic>[];
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
              basalBodyTemperature: 97.3,
            ),
          );
        }

        final result = calculator.predictFuturePeriods(
          cycleLogs,
          symptomLogs: symptoms.cast(),
          count: 2,
        );

        expect(result.length, 2);
        // First: STM-confirmed → ovulation day 6 (Mar 6) + 14 = Mar 20
        expect(result.first, DateTime.utc(2026, 3, 20));
        // Second: built on the statistical model using the first projection as anchor
        expect(result[1].isAfter(result.first), isTrue);
      });
    });
  });
}
