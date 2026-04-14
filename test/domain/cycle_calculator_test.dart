import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/domain/cycle_calculator.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';
import '../helpers/test_model_factory.dart';

void main() {
  group('CycleCalculator Tests', () {
    test('predictNextPeriod with empty logs should return null', () {
      final prediction = CycleCalculator.predictNextPeriod([]);
      expect(prediction, isNull);
    });

    test('predictNextPeriod with one log should return startDate + 28 days', () {
      final start = DateTime.utc(2026, 3, 1);
      final logs = [TestModelFactory.createCycleLog(startDate: start)];
      
      final prediction = CycleCalculator.predictNextPeriod(logs);
      expect(prediction, start.add(const Duration(days: 28)));
    });

    test('predictNextPeriod with multiple logs should use weighted average', () {
      final logs = [
        TestModelFactory.createCycleLog(startDate: DateTime(2026, 4, 28)),
        TestModelFactory.createCycleLog(startDate: DateTime.utc(2026, 3, 29)),
        TestModelFactory.createCycleLog(startDate: DateTime.utc(2026, 3, 1)),
      ];
      
      final prediction = CycleCalculator.predictNextPeriod(logs);
      expect(prediction, DateTime(2026, 4, 28).add(const Duration(days: 29)));
    });

    test('predictNextPeriod should filter outliers with IQR', () {
      final base = DateTime(2026, 1, 1);
      final logs = [
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 157))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 129))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 101))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 56))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 28))),
        TestModelFactory.createCycleLog(startDate: base),
      ];
      
      final prediction = CycleCalculator.predictNextPeriod(logs);
      expect(prediction, logs.first.startDate.add(const Duration(days: 28)));
    });

    test('predictNextPeriod should apply exponential decay weights', () {
      final base = DateTime(2026, 1, 1);
      final logs = [
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 84))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 52))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 24))),
        TestModelFactory.createCycleLog(startDate: base),
      ];
      
      final prediction = CycleCalculator.predictNextPeriod(logs);
      expect(prediction, logs.first.startDate.add(const Duration(days: 28)));
    });

    test('isCurrentlyInPeriod should detect active period if no endDate', () {
      final logs = [TestModelFactory.createCycleLog(startDate: DateTime.now())];
      expect(CycleCalculator.isCurrentlyInPeriod(logs), isTrue);
    });

    test('isCurrentlyInPeriod should expire after 7 days if no endDate', () {
      final logs = [TestModelFactory.createCycleLog(startDate: DateTime.now().subtract(const Duration(days: 8)))];
      expect(CycleCalculator.isCurrentlyInPeriod(logs), isFalse);
    });

    test('predictNextPeriod with uniform cycles should keep all values through IQR', () {
      final base = DateTime(2026, 1, 1);
      final logs = [
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 168))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 140))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 112))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 84))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 56))),
        TestModelFactory.createCycleLog(startDate: base.add(const Duration(days: 28))),
      ];
      
      final prediction = CycleCalculator.predictNextPeriod(logs);
      expect(prediction, logs.first.startDate.add(const Duration(days: 28)));
    });

    group('Ovulation Confirmation (3-over-6 Rule)', () {
      test('confirmOvulation returns null if fewer than 9 logs', () {
        final logs = List.generate(8, (i) => TestModelFactory.createSymptomLog(
          date: DateTime.utc(2026, 3, i + 1),
          basalBodyTemperature: 97.0 + i * 0.1,
        ));
        expect(CycleCalculator.confirmOvulation(logs), isNull);
      });

      test('confirmOvulation detects valid shift', () {
        final logs = <SymptomLog>[];
        final baseDate = DateTime.utc(2026, 3, 1);
        for (int i = 0; i < 6; i++) {
          logs.add(TestModelFactory.createSymptomLog(date: baseDate.add(Duration(days: i)), basalBodyTemperature: 97.0));
        }
        for (int i = 6; i < 9; i++) {
          logs.add(TestModelFactory.createSymptomLog(date: baseDate.add(Duration(days: i)), basalBodyTemperature: 97.2));
        }

        final result = CycleCalculator.confirmOvulation(logs);
        expect(result, DateTime.utc(2026, 3, 6));
      });

      test('confirmOvulation prioritizes most recent shift', () {
        final logs = <SymptomLog>[];
        final baseDate = DateTime.utc(2026, 3, 1);
        
        for (int i = 0; i < 6; i++) {
          logs.add(TestModelFactory.createSymptomLog(date: baseDate.add(Duration(days: i)), basalBodyTemperature: 97.0));
        }
        for (int i = 6; i < 9; i++) {
          logs.add(TestModelFactory.createSymptomLog(date: baseDate.add(Duration(days: i)), basalBodyTemperature: 97.3));
        }
        
        for (int i = 9; i < 14; i++) {
          logs.add(TestModelFactory.createSymptomLog(date: baseDate.add(Duration(days: i)), basalBodyTemperature: 97.3));
        }
        for (int i = 14; i < 17; i++) {
          logs.add(TestModelFactory.createSymptomLog(date: baseDate.add(Duration(days: i)), basalBodyTemperature: 97.6));
        }

        final result = CycleCalculator.confirmOvulation(logs);
        expect(result, DateTime.utc(2026, 3, 14));
      });

      test('confirmOvulation fails if data is missing', () {
        final logs = <SymptomLog>[];
        final baseDate = DateTime.utc(2026, 3, 1);
        for (int i = 0; i < 9; i++) {
          logs.add(TestModelFactory.createSymptomLog(
            date: baseDate.add(Duration(days: i)),
            basalBodyTemperature: (i == 4) ? null : 97.0 + (i >= 6 ? 0.3 : 0),
          ));
        }
        expect(CycleCalculator.confirmOvulation(logs), isNull);
      });
    });

    group('Prediction Override Tests', () {
      test('predictNextPeriod overrides using confirmed ovulation', () {
        final cycleLogs = [TestModelFactory.createCycleLog(startDate: DateTime.utc(2026, 3, 1))];
        
        final symptoms = <SymptomLog>[];
        final baseDate = DateTime.utc(2026, 3, 1);
        for (int i = 0; i < 6; i++) {
          symptoms.add(TestModelFactory.createSymptomLog(date: baseDate.add(Duration(days: i)), basalBodyTemperature: 97.0));
        }
        for (int i = 6; i < 9; i++) {
          symptoms.add(TestModelFactory.createSymptomLog(date: baseDate.add(Duration(days: i)), basalBodyTemperature: 97.2));
        }

        final prediction = CycleCalculator.predictNextPeriod(cycleLogs, symptoms);
        expect(prediction, DateTime.utc(2026, 3, 20));
      });

      test('predictNextPeriod uses default if no ovulation confirmed', () {
        final cycleLogs = [TestModelFactory.createCycleLog(startDate: DateTime.utc(2026, 3, 1))];
        final symptoms = [TestModelFactory.createSymptomLog(date: DateTime.utc(2026, 3, 1), basalBodyTemperature: 97.0)];

        final prediction = CycleCalculator.predictNextPeriod(cycleLogs, symptoms);
        expect(prediction, DateTime.utc(2026, 3, 1).add(const Duration(days: 28)));
      });
    });
  });
}
