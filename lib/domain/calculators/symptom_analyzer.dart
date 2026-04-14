import '../models/trends.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';


/// Utility for analyzing symptom frequency and mood trends.
/// 
/// 💼 **Domain Context**: Provides categorical analysis of health biomarkers,
/// identifying prevalent patterns in user-reported data.
class SymptomAnalyzer {
  static List<MapEntry<String, int>> calculateTopSymptoms(List<SymptomLog> logs) {
    final Map<String, int> counts = {};

    for (var log in logs) {
      for (var symptom in log.symptoms) {
        counts[symptom] = (counts[symptom] ?? 0) + 1;
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).toList();
  }

  static List<MoodPoint> getMoodHistory(List<SymptomLog> logs) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final recentLogs = logs.where((l) => l.date.isAfter(thirtyDaysAgo)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return recentLogs.map((l) => MoodPoint(l.date, l.moodRating)).toList();
  }
}
