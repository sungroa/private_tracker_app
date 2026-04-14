import '../models/cycle_log.dart';

/// Engine responsible for projecting future menstruation and fertility events.
/// 
/// 💼 **Domain Context**: Encapsulates the mathematical models used for 
/// temporal projections. It implements standard fertility awareness protocols,
/// assuming a statistical luteal phase of 14 days.
class PredictionEngine {
  /// Predicts the next period start date based on historical average cycle length.
  /// 
  /// [logs] The historical cycle data.
  /// [avgLength] The calculated average cycle length for the user.
  /// 
  /// Returns the estimated start date of the next period, or null if no data is available.
  static DateTime? predictNextPeriod(List<CycleLog> logs, double avgLength) {
    if (logs.isEmpty) return null;
    
    // Sort logs to ensure we're using the most recent entry
    final latest = List<CycleLog>.from(logs)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    
    // Naive prediction: Start of last period + Average Cycle Length
    return latest.first.startDate.add(Duration(days: avgLength.round()));
  }

  /// Projects the fertile window for the upcoming cycle.
  /// 
  /// [nextPeriodStart] The predicted start date of the next period.
  /// 
  /// Following the Standard Days Method/Calendar Method:
  /// - Assumes a 14-day luteal phase (ovulation happens 14 days before the next period).
  /// - The fertile window is defined as the 5 days preceding ovulation plus the day of ovulation itself (6 days total).
  /// 
  /// Returns a list of [DateTime] objects representing the 6-day fertile window.
  static List<DateTime> predictFertilityWindow(DateTime? nextPeriodStart) {
    if (nextPeriodStart == null) return [];

    // Luteal phase is statistically most consistent at ~14 days for most users.
    final ovulation = nextPeriodStart.subtract(const Duration(days: 14));
    
    // Generate the 6-day window (5 days leading up + ovulation day)
    return List.generate(6, (i) => ovulation.subtract(Duration(days: 5 - i)));
  }
}
