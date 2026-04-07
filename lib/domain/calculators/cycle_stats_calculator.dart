import '../models/cycle_log.dart';

class CycleStatsCalculator {
  static const int defaultCycleLength = 28;

  static double calculateAverageCycleLength(List<CycleEvent> logs) {
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

  static double calculateAveragePeriodDuration(List<CycleEvent> logs) {
    final completedLogs = logs.where((l) => l.endDate != null).toList();
    if (completedLogs.isEmpty) return 5.0; // Default

    int totalDays = 0;
    for (var log in completedLogs) {
      totalDays += log.endDate!.difference(log.startDate).inDays + 1;
    }

    return totalDays / completedLogs.length;
  }

  static List<int> filterOutliers(List<int> lengths) {
    if (lengths.length < 4) return lengths;

    final sorted = List<int>.from(lengths)..sort();
    final n = sorted.length;

    final q1 = sorted[(n / 4).floor()];
    final q3 = sorted[(n * 3 / 4).floor()];
    final iqr = q3 - q1;

    final lowerBound = q1 - 1.5 * iqr;
    final upperBound = q3 + 1.5 * iqr;

    return lengths.where((l) => l >= lowerBound && l <= upperBound).toList();
  }

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
}
