import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/trends_calculator.dart';

void main() {
  group('TrendsCalculator Tests', () {
    test('calculateAverageCycleLength calculates correctly from multiple logs', () {
      final now = DateTime.now();
      final logs = [
        CycleEvent(startDate: now), // Today
        CycleEvent(startDate: now.subtract(const Duration(days: 30))), // 30 days ago
        CycleEvent(startDate: now.subtract(const Duration(days: 58))), // 28 days ago
      ];

      final trends = TrendsCalculator.calculateTrends(logs, []);
      // Average: (30 + 28) / 2 = 29.0
      expect(trends.averageCycleLength, closeTo(29.0, 0.1));
    });

    test('calculateAveragePeriodDuration calculates correctly from completed logs', () {
      final now = DateTime.now();
      final logs = [
        CycleEvent(
          startDate: now.subtract(const Duration(days: 30)), 
          endDate: now.subtract(const Duration(days: 25)),
        ), // 6 days duration (25, 26, 27, 28, 29, 30? Wait, subtraction days)
        // Duration: difference + 1. (30 - 25) + 1 = 6.
        CycleEvent(
          startDate: now.subtract(const Duration(days: 60)),
          endDate: now.subtract(const Duration(days: 56)),
        ), // 5 days duration (60-56)+1
      ];

      final trends = TrendsCalculator.calculateTrends(logs, []);
      // Average: (6 + 5) / 2 = 5.5
      expect(trends.averagePeriodDuration, closeTo(5.5, 0.1));
    });

    test('calculateTopSymptoms counts and sorts correctly', () {
      final logs = [
        SymptomLog(
          date: DateTime.now(), 
          symptoms: ['Cramps', 'Bloating'], 
          moodRating: 3,
        ),
        SymptomLog(
          date: DateTime.now().subtract(const Duration(days: 1)), 
          symptoms: ['Cramps', 'Fatigue'], 
          moodRating: 1,
        ),
        SymptomLog(
          date: DateTime.now().subtract(const Duration(days: 2)), 
          symptoms: ['Cramps'], 
          moodRating: 2,
        ),
      ];

      final trends = TrendsCalculator.calculateTrends([], logs);
      expect(trends.topSymptoms.first.key, 'Cramps');
      expect(trends.topSymptoms.first.value, 3);
      expect(trends.topSymptoms.any((e) => e.key == 'Bloating'), true);
      expect(trends.topSymptoms.any((e) => e.key == 'Fatigue'), true);
    });

    test('getMoodHistory returns sorted points within 30 days', () {
      final now = DateTime.now();
      final logs = [
        SymptomLog(date: now, symptoms: [], moodRating: 5),
        SymptomLog(date: now.subtract(const Duration(days: 10)), symptoms: [], moodRating: 4),
        SymptomLog(date: now.subtract(const Duration(days: 40)), symptoms: [], moodRating: 1), // Outside range
      ];

      final trends = TrendsCalculator.calculateTrends([], logs);
      expect(trends.moodHistory.length, 2);
      expect(trends.moodHistory.first.rating, 4); // Older first (sorted by date)
      expect(trends.moodHistory.last.rating, 5); // Newer last
    });
  });
}
