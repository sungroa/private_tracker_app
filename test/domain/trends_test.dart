import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/core/services/clock.dart';
import 'package:private_tracker_app/domain/cycle_calculator.dart';
import 'package:private_tracker_app/domain/trends_calculator.dart';

import '../helpers/test_model_factory.dart';

void main() {
  late TrendsCalculator trendsCalculator;

  setUp(() {
    final clock = SystemClock();
    final cycleCalculator = CycleCalculator(clock);
    trendsCalculator = TrendsCalculator(cycleCalculator);
  });

  group('TrendsCalculator Tests', () {
    test('calculateAverageCycleLength calculates correctly from multiple logs', () {
      final now = DateTime.now();
      final logs = [
        TestModelFactory.createCycleLog(startDate: now), // Today
        TestModelFactory.createCycleLog(
          startDate: now.subtract(const Duration(days: 30)),
        ), // 30 days ago
        TestModelFactory.createCycleLog(
          startDate: now.subtract(const Duration(days: 58)),
        ), // 28 days ago
      ];

      final trends = trendsCalculator.calculateTrends(logs, []);
      // Average: (30 + 28) / 2 = 29.0
      expect(trends.averageCycleLength, closeTo(29.0, 0.1));
    });

    test('calculateAveragePeriodDuration calculates correctly from completed logs', () {
      final now = DateTime.now();
      final logs = [
        TestModelFactory.createCycleLog(
          startDate: now.subtract(const Duration(days: 30)),
          endDate: now.subtract(const Duration(days: 25)),
        ), // 6 days duration (25, 26, 27, 28, 29, 30? Wait, subtraction days)
        // Duration: difference + 1. (30 - 25) + 1 = 6.
        TestModelFactory.createCycleLog(
          startDate: now.subtract(const Duration(days: 60)),
          endDate: now.subtract(const Duration(days: 56)),
        ), // 5 days duration (60-56)+1
      ];

      final trends = trendsCalculator.calculateTrends(logs, []);
      // Average: (6 + 5) / 2 = 5.5
      expect(trends.averagePeriodDuration, closeTo(5.5, 0.1));
    });

    test('calculateTopSymptoms counts and sorts correctly', () {
      final logs = [
        TestModelFactory.createSymptomLog(
          date: DateTime.now(),
          symptoms: const ['Cramps', 'Bloating'],
          moodRating: 3,
        ),
        TestModelFactory.createSymptomLog(
          date: DateTime.now().subtract(const Duration(days: 1)),
          symptoms: const ['Cramps', 'Fatigue'],
          moodRating: 1,
        ),
        TestModelFactory.createSymptomLog(
          date: DateTime.now().subtract(const Duration(days: 2)),
          symptoms: const ['Cramps'],
          moodRating: 2,
        ),
      ];

      final trends = trendsCalculator.calculateTrends([], logs);
      expect(trends.topSymptoms.first.key, 'Cramps');
      expect(trends.topSymptoms.first.value, 3);
      expect(trends.topSymptoms.any((e) => e.key == 'Bloating'), true);
      expect(trends.topSymptoms.any((e) => e.key == 'Fatigue'), true);
    });

    test('getMoodHistory returns sorted points within 30 days', () {
      final now = DateTime.now();
      final logs = [
        TestModelFactory.createSymptomLog(date: now, symptoms: const [], moodRating: 5),
        TestModelFactory.createSymptomLog(
          date: now.subtract(const Duration(days: 10)),
          symptoms: const [],
          moodRating: 4,
        ),
        TestModelFactory.createSymptomLog(
          date: now.subtract(const Duration(days: 40)),
          symptoms: const [],
          moodRating: 1,
        ), // Outside range
      ];

      final trends = trendsCalculator.calculateTrends([], logs);
      expect(trends.moodHistory.length, 2);
      expect(trends.moodHistory.first.rating, 4); // Older first (sorted by date)
      expect(trends.moodHistory.last.rating, 5); // Newer last
    });
  });
}
