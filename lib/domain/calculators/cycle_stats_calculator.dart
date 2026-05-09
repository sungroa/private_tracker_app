import 'dart:math';
import '../models/cycle_log.dart';

/// Statistical utilities for menstruation cycle data analysis.
/// 
/// 💼 **Domain Context**: This calculator handles the heavy mathematical lifting
/// for long-term data trends. It utilizes statistical methodologies like
/// Interquartile Range (IQR) for outlier filtering and Exponential Decay for
/// weighted averages.
class CycleStatsCalculator {
  static const int defaultCycleLength = 28;

  static double calculateAverageCycleLength(List<CycleLog> logs) {
    if (logs.length < 2) return defaultCycleLength.toDouble();

    final sortedLogs = List<CycleLog>.from(logs)
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

  static double calculateAveragePeriodDuration(List<CycleLog> logs) {
    final completedLogs = logs.where((l) => l.endDate != null).toList();
    if (completedLogs.isEmpty) return 5.0; // Default

    int totalDays = 0;
    for (var log in completedLogs) {
      totalDays += log.endDate!.difference(log.startDate).inDays + 1;
    }

    return totalDays / completedLogs.length;
  }

  /// Filters out abnormal cycle lengths using the Interquartile Range (IQR) method.
  /// 
  /// **Why**: Cycle lengths can occasionally be highly irregular due to illness, 
  /// stress, or mislogged data. If included, these extreme outliers would skew the 
  /// exponential moving average and cause wild inaccuracies in future predictions.
  /// 
  /// **How**: Calculates the Q1 (25th percentile) and Q3 (75th percentile). Any 
  /// cycle length falling below `Q1 - 1.5 * IQR` or above `Q3 + 1.5 * IQR` is dropped.
  /// A minimum of 4 cycles is required to establish statistical quartiles.
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

  /// Calculates a weighted average using exponential decay.
  /// More recent values (lower index) receive higher weight.
  /// Uses a decay factor of 0.85 so all data contributes,
  /// but recent cycles dominate the prediction.
  static int calculateWeightedAverage(List<int> lengths, {double decayFactor = 0.85}) {
    if (lengths.isEmpty) return defaultCycleLength;

    double weightedSum = 0;
    double totalWeight = 0;

    for (int i = 0; i < lengths.length; i++) {
      final weight = pow(decayFactor, i);
      weightedSum += lengths[i] * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return defaultCycleLength;
    return (weightedSum / totalWeight).round();
  }
}
