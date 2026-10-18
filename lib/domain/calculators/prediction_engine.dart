import 'dart:developer' as developer;

/// Engine responsible for projecting future menstruation and fertility events.
///
/// 💼 **Domain Context**: Encapsulates the mathematical models used for
/// temporal projections. It implements standard fertility awareness protocols,
/// assuming a statistical luteal phase of 14 days.
class PredictionEngine {
  /// Projects the fertile window for a single upcoming cycle.
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
    final window = List.generate(6, (i) => ovulation.subtract(Duration(days: 5 - i)));

    developer.log(
      'Fertile Window: ${window.first.toIso8601String()} to ${window.last.toIso8601String()}',
      name: 'PrivacyTracker.Prediction',
    );

    return window;
  }

  /// Projects and merges fertility windows for all [periodStarts], returning
  /// a deduplicated, chronologically sorted list of fertile days.
  ///
  /// This is the multi-cycle variant of [predictFertilityWindow]. It flat-maps
  /// the 6-day window for each projected period start date. Any days that appear
  /// in overlapping windows (possible when consecutive cycles are very short) are
  /// automatically deduplicated.
  ///
  /// Returns an empty list when [periodStarts] is empty.
  static List<DateTime> predictAllFertilityWindows(List<DateTime> periodStarts) {
    if (periodStarts.isEmpty) return [];

    final Set<String> seen = {};
    final List<DateTime> allDates = [];

    for (final periodStart in periodStarts) {
      final window = predictFertilityWindow(periodStart);
      for (final day in window) {
        // Deduplicate using date-only string key (ignores time component)
        final key = '${day.year}-${day.month}-${day.day}';
        if (seen.add(key)) {
          allDates.add(DateTime(day.year, day.month, day.day));
        }
      }
    }

    allDates.sort((a, b) => a.compareTo(b));

    developer.log(
      'All Fertility Windows: ${allDates.length} unique days across ${periodStarts.length} cycles',
      name: 'PrivacyTracker.Prediction',
    );

    return allDates;
  }
}
