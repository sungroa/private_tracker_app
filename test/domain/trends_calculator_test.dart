import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/trends_calculator.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';


void main() {
  group('TrendsCalculator BBT Mapping', () {
    final now = DateTime(2026, 4, 1);
    
    final cycleLogs = [
      CycleEvent(startDate: now.subtract(const Duration(days: 5))), // Cycle started 5 days ago
    ];

    final symptomLogs = [
      SymptomLog(
        date: now.subtract(const Duration(days: 4)),
        symptoms: const ['Cramps'],
        moodRating: 3,
        basalBodyTemperature: 36.5,
      ),
      SymptomLog(
        date: now.subtract(const Duration(days: 3)),
        symptoms: const [],
        moodRating: 4,
        basalBodyTemperature: 36.6,
        lhTestPositive: true,
      ),
      SymptomLog(
        date: now.subtract(const Duration(days: 2)),
        symptoms: const ['Headache'],
        moodRating: 2,
        basalBodyTemperature: 36.4,
      ),
    ];

    test('should map symptom logs to correct cycle days', () {
      final trends = TrendsCalculator.calculateTrends(cycleLogs, symptomLogs);
      
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
        SymptomLog(
          date: now.subtract(const Duration(days: 1)),
          symptoms: const [],
          moodRating: 5,
        ), // No BBT
      ];
      
      final trends = TrendsCalculator.calculateTrends(cycleLogs, logsWithMissingBbt);
      expect(trends.bbtHistory.length, 3);
    });

    test('should only include logs from the current cycle', () {
      final multipleCycles = [
        CycleEvent(startDate: now.subtract(const Duration(days: 5))), // Current
        CycleEvent(startDate: now.subtract(const Duration(days: 35))), // Previous
      ];
      
      final oldLogs = [
        SymptomLog(
          date: now.subtract(const Duration(days: 34)),
          symptoms: const [],
          moodRating: 3,
          basalBodyTemperature: 36.8,
        ),
      ];
      
      final trends = TrendsCalculator.calculateTrends(multipleCycles, [...oldLogs, ...symptomLogs]);
      
      // Should only have the 3 logs from the current cycle
      expect(trends.bbtHistory.length, 3);
      expect(trends.bbtHistory.every((p) => p.cycleDay < 10), true);
    });
  });
}
