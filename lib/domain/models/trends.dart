
class TrendData {
  final double averageCycleLength;
  final double averagePeriodDuration;
  final List<MapEntry<String, int>> topSymptoms;
  final List<MoodPoint> moodHistory;
  final List<BbtPoint> bbtHistory;
  final DateTime? predictedNextPeriod;
  final List<DateTime> predictedFertilityDates;

  TrendData({
    required this.averageCycleLength,
    required this.averagePeriodDuration,
    required this.topSymptoms,
    required this.moodHistory,
    this.bbtHistory = const [],
    this.predictedNextPeriod,
    this.predictedFertilityDates = const [],
  });
}

class MoodPoint {
  final DateTime date;
  final int rating;

  MoodPoint(this.date, this.rating);
}

class BbtPoint {
  final int cycleDay;
  final double temperature;
  final bool hasLhSurge;
  final List<String> symptoms;
  final DateTime date;

  BbtPoint({
    required this.cycleDay,
    required this.temperature,
    required this.date,
    this.hasLhSurge = false,
    this.symptoms = const [],
  });
}
