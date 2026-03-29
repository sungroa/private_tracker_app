import 'models/cycle_log.dart';

class CycleCalculator {
  // Average cycle length (default 28 days)
  static const int defaultCycleLength = 28;

  /// Predicts the next period start date based on previous logs.
  static DateTime predictNextPeriod(List<CycleLog> logs) {
    if (logs.isEmpty) {
      return DateTime.now().add(const Duration(days: defaultCycleLength));
    }

    // Sort newest first
    final sortedLogs = List<CycleLog>.from(logs)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    if (sortedLogs.length < 2) {
      return sortedLogs.first.startDate.add(const Duration(days: defaultCycleLength));
    }

    // 1. Extract cycle lengths (days between starts)
    final lengths = <int>[];
    for (int i = 0; i < sortedLogs.length - 1; i++) {
      lengths.add(
        sortedLogs[i].startDate.difference(sortedLogs[i + 1].startDate).inDays,
      );
    }

    // 2. Filter outliers using IQR (require at least 4 intervals for statistical significance)
    final filteredLengths = _filterOutliers(lengths);

    // 3. Calculate weighted average of valid cycles (favoring recent ones)
    final averageLength = _calculateWeightedAverage(filteredLengths);

    return sortedLogs.first.startDate.add(Duration(days: averageLength));
  }

  /// Excludes anomalous cycle lengths using the Interquartile Range (IQR) method.
  static List<int> _filterOutliers(List<int> lengths) {
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
  /// Decal weights: 50% for newest, 30% for previous, 20% for 3rd previous.
  static int _calculateWeightedAverage(List<int> lengths) {
    if (lengths.isEmpty) return defaultCycleLength;

    final weights = [0.5, 0.3, 0.2];
    double weightedSum = 0;
    double totalWeight = 0;

    for (int i = 0; i < lengths.length && i < weights.length; i++) {
      weightedSum += lengths[i] * weights[i];
      totalWeight += weights[i];
    }

    // Fallback to simple average if weighted sum fails or for older cycles beyond the first 3
    if (totalWeight == 0) return defaultCycleLength;

    return (weightedSum / totalWeight).round();
  }

  /// Calculates the current cycle day (1, 2, 3...)
  static int currentCycleDay(DateTime lastPeriodStart) {
    return DateTime.now().difference(lastPeriodStart).inDays + 1;
  }

  /// Checks if the user is currently in their period.
  static bool isCurrentlyInPeriod(List<CycleLog> logs) {
    if (logs.isEmpty) return false;
    logs.sort((a, b) => b.startDate.compareTo(a.startDate));
    final latest = logs.first;

    // Period usually lasts 3-7 days if not ended yet
    if (latest.endDate == null) {
      final daysSinceStart = DateTime.now().difference(latest.startDate).inDays;
      return daysSinceStart >= 0 && daysSinceStart < 7;
    }

    final now = DateTime.now();
    return now.isAfter(latest.startDate) && now.isBefore(latest.endDate!.add(const Duration(days: 1)));
  }
}
