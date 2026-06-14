import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/domain/trends_calculator.dart';
import 'package:private_tracker_app/domain/cycle_calculator.dart';
import 'package:private_tracker_app/core/services/clock.dart';
import '../helpers/test_model_factory.dart';

void main() {
  late TrendsCalculator trendsCalculator;

  setUp(() {
    final clock = SystemClock();
    final cycleCalculator = CycleCalculator(clock);
    trendsCalculator = TrendsCalculator(cycleCalculator);
  });

  group('TrendsCalculator BBT Mapping', () {
    final now = DateTime(2026, 4, 1);
    
    final cycleLogs = [
      TestModelFactory.createCycleLog(startDate: now.subtract(const Duration(days: 5))), // Cycle started 5 days ago
    ];

    final symptomLogs = [
      TestModelFactory.createSymptomLog(
        date: now.subtract(const Duration(days: 4)),
        symptoms: const ['Cramps'],
        moodRating: 3,
        basalBodyTemperature: 36.5,
      ),
      TestModelFactory.createSymptomLog(
        date: now.subtract(const Duration(days: 3)),
        moodRating: 4,
        basalBodyTemperature: 36.6,
        lhTestPositive: true,
      ),
      TestModelFactory.createSymptomLog(
        date: now.subtract(const Duration(days: 2)),
        moodRating: 2,
        basalBodyTemperature: 36.4,
      ),
    ];

    test('should map symptom logs to correct cycle days', () {
      final trends = trendsCalculator.calculateTrends(cycleLogs, symptomLogs);
      
      expect(trends.bbtHistory.length, 3);
      
      // Day 1 is the start date (now - 5)
      // log1 is (now - 4) -> Cycle Day 2
      expect(trends.bbtHistory[0].cycleDay, 2);
      expect(trends.bbtHistory[0].temperature, 36.5);
      
      // log2 is (now - 3) -> Cycle Day 3
      expect(trends.bbtHistory[1].cycleDay, 3);
      expect(trends.bbtHistory[1].hasLhSurge, true);
      
      // log3 is (now - 2) -> Cycle Day 4
      expect(trends.bbtHistory[2].cycleDay, 4);
    });

    test('should only include logs with BBT', () {
      final logsWithMissingBbt = [
        ...symptomLogs,
        TestModelFactory.createSymptomLog(
          date: now.subtract(const Duration(days: 1)),
          moodRating: 5,
          basalBodyTemperature: null,
        ), // No BBT
      ];
      
      final trends = trendsCalculator.calculateTrends(cycleLogs, logsWithMissingBbt);
      expect(trends.bbtHistory.length, 3);
    });

    test('should only include logs from the current cycle', () {
      final multipleCycles = [
        TestModelFactory.createCycleLog(startDate: now.subtract(const Duration(days: 5))), // Current
        TestModelFactory.createCycleLog(startDate: now.subtract(const Duration(days: 35))), // Previous
      ];
      
      final oldLogs = [
        TestModelFactory.createSymptomLog(
          date: now.subtract(const Duration(days: 34)),
          moodRating: 3,
          basalBodyTemperature: 36.8,
        ),
      ];
      
      final trends = trendsCalculator.calculateTrends(multipleCycles, [...oldLogs, ...symptomLogs]);
      
      // Should only have the 3 logs from the current cycle
      expect(trends.bbtHistory.length, 3);
      expect(trends.bbtHistory.every((p) => p.cycleDay < 10), true);
    });
  });

  group('TrendsCalculator Multi-Cycle Predictions', () {
    test('predictedPeriodStarts is empty when no cycle logs provided', () {
      final trends = trendsCalculator.calculateTrends([], []);
      expect(trends.predictedPeriodStarts, isEmpty);
      expect(trends.predictedNextPeriod, isNull);
    });

    test('predictedNextPeriod getter delegates to predictedPeriodStarts.first', () {
      final cycleStart = DateTime.utc(2026, 1, 1);
      final logs = [
        TestModelFactory.createCycleLog(startDate: cycleStart),
      ];
      final trends = trendsCalculator.calculateTrends(logs, []);
      expect(trends.predictedNextPeriod, trends.predictedPeriodStarts.first);
    });

    test('returns 1 projection for cold start (1 cycle)', () {
      final logs = [
        TestModelFactory.createCycleLog(startDate: DateTime.utc(2026, 3, 1)),
      ];
      final trends = trendsCalculator.calculateTrends(logs, []);
      expect(trends.predictedPeriodStarts.length, 1);
    });

    test('returns 4 projections for well-established history (9+ cycles)', () {
      final base = DateTime.utc(2026, 1, 1);
      final logs = List.generate(
        9,
        (i) => TestModelFactory.createCycleLog(startDate: base.add(Duration(days: i * 28))),
      ).reversed.toList();
      final trends = trendsCalculator.calculateTrends(logs, []);
      expect(trends.predictedPeriodStarts.length, 4);
    });

    test('predictedPeriodStarts are in chronological order', () {
      final base = DateTime.utc(2026, 1, 1);
      final logs = List.generate(
        9,
        (i) => TestModelFactory.createCycleLog(startDate: base.add(Duration(days: i * 28))),
      ).reversed.toList();
      final trends = trendsCalculator.calculateTrends(logs, []);
      final periods = trends.predictedPeriodStarts;
      for (int i = 1; i < periods.length; i++) {
        expect(periods[i].isAfter(periods[i - 1]), isTrue);
      }
    });

    test('predictedFertilityDates covers all projected periods (up to 24 days)', () {
      final base = DateTime.utc(2026, 1, 1);
      final logs = List.generate(
        9,
        (i) => TestModelFactory.createCycleLog(startDate: base.add(Duration(days: i * 28))),
      ).reversed.toList();
      final trends = trendsCalculator.calculateTrends(logs, []);
      // 4 projections × 6 days each = up to 24 fertility dates (may be fewer if overlap)
      expect(trends.predictedFertilityDates.length, lessThanOrEqualTo(24));
      expect(trends.predictedFertilityDates.length, greaterThan(6));
    });

    test('isPredictedBleeding returns true for any projected period, not just the first', () {
      final base = DateTime.utc(2026, 1, 1);
      final logs = List.generate(
        9,
        (i) => TestModelFactory.createCycleLog(startDate: base.add(Duration(days: i * 28))),
      ).reversed.toList();
      final trends = trendsCalculator.calculateTrends(logs, []);

      // First projected period should match
      expect(trends.isPredictedBleeding(trends.predictedPeriodStarts.first), isTrue);

      // Last projected period should also match
      expect(trends.isPredictedBleeding(trends.predictedPeriodStarts.last), isTrue);
    });

    test('isPredictedBleeding returns false for dates well outside all projections', () {
      final logs = [
        TestModelFactory.createCycleLog(startDate: DateTime.utc(2026, 3, 1)),
      ];
      final trends = trendsCalculator.calculateTrends(logs, []);
      // A date far in the past should never match
      expect(trends.isPredictedBleeding(DateTime.utc(2020, 1, 1)), isFalse);
    });
  });
}
