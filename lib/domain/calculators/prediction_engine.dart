import '../models/cycle_log.dart';

class PredictionEngine {
  static DateTime? predictNextPeriod(List<CycleEvent> logs, double avgLength) {
    if (logs.isEmpty) return null;
    
    final latest = List<CycleEvent>.from(logs)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    
    return latest.first.startDate.add(Duration(days: avgLength.round()));
  }

  static List<DateTime> predictFertilityWindow(DateTime? nextPeriodStart) {
    if (nextPeriodStart == null) return [];

    final ovulation = nextPeriodStart.subtract(const Duration(days: 14));
    return List.generate(6, (i) => ovulation.subtract(Duration(days: 5 - i)));
  }
}
