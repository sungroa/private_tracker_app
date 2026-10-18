import 'package:private_tracker_app/domain/models/symptom_log.dart';

import '../models/cycle_log.dart';
import '../models/trends.dart';

/// Maps daily health logs to cycle-relative Basal Body Temperature (BBT) data.
///
/// 💼 **Domain Context**: Transforms chronological data into cycle-day relative
/// data points, allowing for comparison across different cycles.
class BbtMapper {
  static List<BbtPoint> getBbtHistoryForCurrentCycle(
    List<CycleLog> cycleLogs,
    List<SymptomLog> symptomLogs,
  ) {
    if (cycleLogs.isEmpty) return [];

    final sortedCycles = List<CycleLog>.from(cycleLogs)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final latestCycleStart = sortedCycles.first.startDate;

    final currentCycleEvents = symptomLogs.where((log) {
      return (log.date.isAtSameMomentAs(latestCycleStart) || log.date.isAfter(latestCycleStart));
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    return currentCycleEvents.where((log) => log.basalBodyTemperature != null).map((log) {
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
