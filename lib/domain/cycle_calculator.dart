import 'package:intl/intl.dart';
import '../models/cycle_log.dart';

class CycleCalculator {
  // Average cycle length (default 28 days)
  static const int defaultCycleLength = 28;

  /// Predicts the next period start date based on previous logs.
  static DateTime predictNextPeriod(List<CycleLog> logs) {
    if (logs.isEmpty) {
      return DateTime.now().add(const Duration(days: defaultCycleLength));
    }

    logs.sort((a, b) => b.startDate.compareTo(a.startDate)); // Newest first

    // Calculate average cycle length from last 3-6 cycles
    if (logs.length >= 2) {
      int totalDays = 0;
      int count = 0;
      for (int i = 0; i < logs.length - 1 && i < 6; i++) {
        totalDays += logs[i].startDate.difference(logs[i + 1].startDate).inDays;
        count++;
      }
      final averageLength = (totalDays / count).round();
      return logs.first.startDate.add(Duration(days: averageLength));
    }

    return logs.first.startDate.add(const Duration(days: defaultCycleLength));
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
