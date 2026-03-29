import 'models/cycle_log.dart';

class TrendData {
  final double averageCycleLength;
  final double averagePeriodDuration;
  final List<MapEntry<String, int>> topSymptoms;
  final List<MoodPoint> moodHistory;

  TrendData({
    required this.averageCycleLength,
    required this.averagePeriodDuration,
    required this.topSymptoms,
    required this.moodHistory,
  });
}

class MoodPoint {
  final DateTime date;
  final int rating;

  MoodPoint(this.date, this.rating);
}

class TrendsCalculator {
  /// Aggregates all necessary trend data from the provided logs.
  static TrendData calculateTrends(List<CycleLog> cycleLogs, List<SymptomLog> symptomLogs) {
    return TrendData(
      averageCycleLength: _calculateAverageCycleLength(cycleLogs),
      averagePeriodDuration: _calculateAveragePeriodDuration(cycleLogs),
      topSymptoms: _calculateTopSymptoms(symptomLogs),
      moodHistory: _getMoodHistory(symptomLogs),
    );
  }

  static double _calculateAverageCycleLength(List<CycleLog> logs) {
    if (logs.length < 2) return 28.0; // Default

    final sortedLogs = List<CycleLog>.from(logs)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    int totalDays = 0;
    int count = 0;

    for (int i = 0; i < sortedLogs.length - 1 && i < 6; i++) {
      totalDays += sortedLogs[i].startDate.difference(sortedLogs[i + 1].startDate).inDays;
      count++;
    }

    return count > 0 ? totalDays / count : 28.0;
  }

  static double _calculateAveragePeriodDuration(List<CycleLog> logs) {
    final completedLogs = logs.where((l) => l.endDate != null).toList();
    if (completedLogs.isEmpty) return 5.0; // Default

    int totalDays = 0;
    for (var log in completedLogs) {
      totalDays += log.endDate!.difference(log.startDate).inDays + 1;
    }

    return totalDays / completedLogs.length;
  }

  static List<MapEntry<String, int>> _calculateTopSymptoms(List<SymptomLog> logs) {
    final Map<String, int> counts = {};

    for (var log in logs) {
      for (var symptom in log.symptoms) {
        counts[symptom] = (counts[symptom] ?? 0) + 1;
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).toList();
  }

  static List<MoodPoint> _getMoodHistory(List<SymptomLog> logs) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final recentLogs = logs.where((l) => l.date.isAfter(thirtyDaysAgo)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return recentLogs.map((l) => MoodPoint(l.date, l.moodRating)).toList();
  }
}
