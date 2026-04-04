import 'models/cycle_log.dart';

class CycleCalculator {
  // Average cycle length (default 28 days)
  static const int defaultCycleLength = 28;

  /// Predicts the next period start date based on previous logs.
  /// If [symptomLogs] are provided, it attempts to mathematically confirm ovulation
  /// using the 3-over-6 rule and overrides the average prediction.
  static DateTime predictNextPeriod(
    List<CycleLog> cycleLogs, [
    List<SymptomLog>? symptomLogs,
    double threshold = 0.2,
  ]) {
    if (cycleLogs.isEmpty) {
      return DateTime.now().add(const Duration(days: defaultCycleLength));
    }

    // Sort newest first
    final sortedCycleLogs = List<CycleLog>.from(cycleLogs)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    // 1. Try to confirm ovulation for the current cycle if symptom logs are available
    if (symptomLogs != null && symptomLogs.isNotEmpty) {
      final latestCycleStart = sortedCycleLogs.first.startDate;
      final currentCycleLogs = symptomLogs
          .where((log) => !log.date.isBefore(latestCycleStart))
          .toList();

      final confirmedOvulation = confirmOvulation(currentCycleLogs, threshold: threshold);
      if (confirmedOvulation != null) {
        // STM standard: Luteal phase is consistently ~14 days
        return confirmedOvulation.add(const Duration(days: 14));
      }
    }

    if (sortedCycleLogs.length < 2) {
      return sortedCycleLogs.first.startDate.add(const Duration(days: defaultCycleLength));
    }

    // 2. Fallback to historical weighted average
    final lengths = <int>[];
    for (int i = 0; i < sortedCycleLogs.length - 1; i++) {
      lengths.add(
        sortedCycleLogs[i].startDate.difference(sortedCycleLogs[i + 1].startDate).inDays,
      );
    }

    final filteredLengths = _filterOutliers(lengths);
    final averageLength = _calculateWeightedAverage(filteredLengths);

    return sortedCycleLogs.first.startDate.add(Duration(days: averageLength));
  }

  /// Implements the Sympto-Thermal Method "3-over-6 rule" to confirm ovulation.
  /// Scans chronologically for 3 consecutive days where BBT is [threshold] higher
  /// than the maximum of the preceding 6 consecutive days.
  /// Returns the day BEFORE the temperature shift (the confirmed ovulation date).
  static DateTime? confirmOvulation(List<SymptomLog> logs, {double threshold = 0.2}) {
    if (logs.length < 9) return null;

    final sorted = List<SymptomLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    DateTime? latestConfirmed;

    // Slide across the logs: i is the first day of the 3-day high-temp shift
    // We need 6 days before i, so starting index is 6.
    for (int i = 6; i <= sorted.length - 3; i++) {
      // 1. Get preceding 6 days
      final preceding6 = sorted.sublist(i - 6, i);
      if (preceding6.any((log) => log.basalBodyTemperature == null)) continue;

      // 2. Get 3 potential shift days
      final shiftDays = sorted.sublist(i, i + 3);
      if (shiftDays.any((log) => log.basalBodyTemperature == null)) continue;

      // Check for continuity in dates (must be consecutive logs)
      bool isConsecutive = true;
      for (int j = i - 6; j < i + 2; j++) {
        if (sorted[j + 1].date.difference(sorted[j].date).inDays != 1) {
          isConsecutive = false;
          break;
        }
      }
      if (!isConsecutive) continue;

      final maxPreceding = preceding6
          .map((l) => l.basalBodyTemperature!)
          .reduce((a, b) => a > b ? a : b);

      final isShiftValidated = shiftDays.every(
        (log) => log.basalBodyTemperature! >= (maxPreceding + threshold),
      );

      if (isShiftValidated) {
        // Ovulation is marked as the day before the first high temp
        latestConfirmed = sorted[i - 1].date;
      }
    }

    return latestConfirmed;
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
