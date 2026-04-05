import 'models/cycle_log.dart';

class TrendData {
  final double averageCycleLength;
  final double averagePeriodDuration;
  final List<MapEntry<String, int>> topSymptoms;
  final List<MoodPoint> moodHistory;
  final List<BbtPoint> bbtHistory;
  final DateTime? predictedNextPeriod;
  final List<DateTime> predictedFertilityDates;

  TrendData({
    required this.averageCycleLength,
    required this.averagePeriodDuration,
    required this.topSymptoms,
    required this.moodHistory,
    this.bbtHistory = const [],
    this.predictedNextPeriod,
    this.predictedFertilityDates = const [],
  });
}

class MoodPoint {
  final DateTime date;
  final int rating;

  MoodPoint(this.date, this.rating);
}

class BbtPoint {
  final int cycleDay;
  final double temperature;
  final bool hasLhSurge;
  final List<String> symptoms;
  final DateTime date;

  BbtPoint({
    required this.cycleDay,
    required this.temperature,
    required this.date,
    this.hasLhSurge = false,
    this.symptoms = const [],
  });
}

class TrendsCalculator {
  static const int defaultCycleLength = 28;

  /// Aggregates all necessary trend data from the provided logs.
  static TrendData calculateTrends(List<CycleEvent> cycleLogs, List<SymptomLog> symptomLogs) {
    final avgCycleLength = _calculateAverageCycleLength(cycleLogs);
    final avgPeriodDuration = _calculateAveragePeriodDuration(cycleLogs);
    
    final nextPeriod = _predictNextPeriod(cycleLogs, avgCycleLength);
    final fertility = _predictFertilityWindow(nextPeriod);

    return TrendData(
      averageCycleLength: avgCycleLength,
      averagePeriodDuration: avgPeriodDuration,
      topSymptoms: _calculateTopSymptoms(symptomLogs),
      moodHistory: _getMoodHistory(symptomLogs),
      bbtHistory: _getBbtHistoryForCurrentCycle(cycleLogs, symptomLogs),
      predictedNextPeriod: nextPeriod,
      predictedFertilityDates: fertility,
    );
  }

  static double _calculateAverageCycleLength(List<CycleEvent> logs) {
    if (logs.length < 2) return defaultCycleLength.toDouble();

    final sortedLogs = List<CycleEvent>.from(logs)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final lengths = <int>[];
    for (int i = 0; i < sortedLogs.length - 1; i++) {
      lengths.add(
        sortedLogs[i].startDate.difference(sortedLogs[i + 1].startDate).inDays,
      );
    }

    final filteredLengths = filterOutliers(lengths);
    return calculateWeightedAverage(filteredLengths).toDouble();
  }

  /// Excludes anomalous cycle lengths using the Interquartile Range (IQR) method.
  static List<int> filterOutliers(List<int> lengths) {
    if (lengths.length < 4) return lengths;

    final sorted = List<int>.from(lengths)..sort();
    final n = sorted.length;

    // Use simple index-based quartiles
    final q1 = sorted[(n / 4).floor()];
    final q3 = sorted[(n * 3 / 4).floor()];
    final iqr = q3 - q1;

    final lowerBound = q1 - 1.5 * iqr;
    final upperBound = q3 + 1.5 * iqr;

    return lengths.where((l) => l >= lowerBound && l <= upperBound).toList();
  }

  /// Calculates a decaying weighted average of cycle lengths.
  /// Weights: 50% for newest, 30% for previous, 20% for 3rd previous.
  static int calculateWeightedAverage(List<int> lengths) {
    if (lengths.isEmpty) return defaultCycleLength;

    final weights = [0.5, 0.3, 0.2];
    double weightedSum = 0;
    double totalWeight = 0;

    for (int i = 0; i < lengths.length && i < weights.length; i++) {
      weightedSum += lengths[i] * weights[i];
      totalWeight += weights[i];
    }

    if (totalWeight == 0) return defaultCycleLength;
    return (weightedSum / totalWeight).round();
  }

  static DateTime? _predictNextPeriod(List<CycleEvent> logs, double avgLength) {
    if (logs.isEmpty) return null;
    
    final latest = List<CycleEvent>.from(logs)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    
    return latest.first.startDate.add(Duration(days: avgLength.round()));
  }

  static List<DateTime> _predictFertilityWindow(DateTime? nextPeriodStart) {
    if (nextPeriodStart == null) return [];

    // Prediction: Ovulation = Next Period - 14 days
    // Window = Ovulation - 5 days to Ovulation
    final ovulation = nextPeriodStart.subtract(const Duration(days: 14));
    return List.generate(6, (i) => ovulation.subtract(Duration(days: 5 - i)));
  }

  static double _calculateAveragePeriodDuration(List<CycleEvent> logs) {
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

  static List<BbtPoint> _getBbtHistoryForCurrentCycle(List<CycleEvent> cycleLogs, List<SymptomLog> symptomLogs) {
    if (cycleLogs.isEmpty) return [];

    final sortedCycles = List<CycleEvent>.from(cycleLogs)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    
    final latestCycleStart = sortedCycles.first.startDate;

    final currentCycleEvents = symptomLogs.where((log) {
      return (log.date.isAtSameMomentAs(latestCycleStart) || log.date.isAfter(latestCycleStart));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return currentCycleEvents
        .where((log) => log.basalBodyTemperature != null)
        .map((log) {
          final cycleDay = log.date.difference(latestCycleStart).inDays + 1;
          return BbtPoint(
            cycleDay: cycleDay,
            temperature: log.basalBodyTemperature!,
            date: log.date,
            hasLhSurge: log.lhTestPositive ?? false,
            symptoms: log.symptoms,
          );
        }).toList();
  }
}
