import '../models/cycle_log.dart';
import 'cycle_length_forecaster.dart';

/// Statistical utilities for menstruation cycle data analysis.
///
/// 💼 **Domain Context**: This calculator handles the aggregation of historical
/// data for long-term trends. It delegates complex forecasting logic to
/// [CycleLengthForecaster] to ensure consistency between displays and projections.
class CycleStatsCalculator {
  static const int defaultCycleLength = 28;

  static double calculateAverageCycleLength(List<CycleLog> logs) {
    if (logs.length < 2) return defaultCycleLength.toDouble();

    final sortedLogs = List<CycleLog>.from(logs)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final lengths = <int>[];
    for (int i = 0; i < sortedLogs.length - 1; i++) {
      lengths.add(sortedLogs[i].startDate.difference(sortedLogs[i + 1].startDate).inDays);
    }

    // Forecaster expects oldest to newest
    final chronologicalLengths = lengths.reversed.toList();
    return CycleLengthForecaster.predictNextLength(chronologicalLengths).toDouble();
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
}
