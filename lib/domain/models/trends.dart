
/// Aggregate model for statistical trends and predictive analysis results.
/// 
/// 💼 **Domain Context**: This is the final output of the [TrendsCalculator]. 
/// It consolidates raw logs into actionable health insights for the UI.
class TrendData {
  /// Historical average length of the menstruation cycle in days.
  final double averageCycleLength;

  /// Historical average duration of the bleeding phase in days.
  final double averagePeriodDuration;

  /// Ranked list of most frequent symptoms with their occurrence counts.
  final List<MapEntry<String, int>> topSymptoms;

  /// Time-series data for mood fluctuations.
  final List<MoodPoint> moodHistory;

  /// Normalized data for Basal Body Temperature (BBT) mapping.
  final List<BbtPoint> bbtHistory;

  /// The estimated start date of the next menstruation cycle.
  final DateTime? predictedNextPeriod;

  /// Estimated dates for the upcoming fertility window.
  final List<DateTime> predictedFertilityDates;

  /// Canonical constructor for [TrendData].
  TrendData({
    required this.averageCycleLength,
    required this.averagePeriodDuration,
    required this.topSymptoms,
    required this.moodHistory,
    this.bbtHistory = const [],
    this.predictedNextPeriod,
    this.predictedFertilityDates = const [],
  });

  /// Checks if a given [date] is within the predicted bleeding window.
  bool isPredictedBleeding(DateTime date) {
    if (predictedNextPeriod == null) return false;
    final dateOnly = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      predictedNextPeriod!.year,
      predictedNextPeriod!.month,
      predictedNextPeriod!.day,
    );
    
    // Projection assumes a 4-day standard window if not otherwise specified.
    final end = start.add(const Duration(days: 4));
    return (dateOnly.isAtSameMomentAs(start) || 
           (dateOnly.isAfter(start) && dateOnly.isBefore(end.add(const Duration(days: 1)))));
  }

  /// Checks if a given [date] is within the predicted fertile window.
  bool isPredictedFertility(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return predictedFertilityDates.any((d) => 
      d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day);
  }
}

/// A specific data point in a mood time-series.
class MoodPoint {
  /// The date of the mood record.
  final DateTime date;
  
  /// The subjective rating (1-5).
  final int rating;

  MoodPoint(this.date, this.rating);
}

/// A specific data point representing Basal Body Temperature and related markers.
/// 
/// 💼 **Domain Context**: Used for FAM (Fertility Awareness Method) mapping.
class BbtPoint {
  /// The day of the cycle (1-indexed).
  final int cycleDay;
  
  /// The temperature reading in degrees.
  final double temperature;
  
  /// Whether an LH surge was detected on this date.
  final bool hasLhSurge;
  
  /// Symptoms recorded on this day.
  final List<String> symptoms;
  
  /// The absolute calendar date.
  final DateTime date;

  BbtPoint({
    required this.cycleDay,
    required this.temperature,
    required this.date,
    this.hasLhSurge = false,
    this.symptoms = const [],
  });
}
