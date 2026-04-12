import 'models/cycle_log.dart';
import 'models/trends.dart';
import 'calculators/cycle_stats_calculator.dart';
import 'calculators/prediction_engine.dart';
import 'calculators/symptom_analyzer.dart';
import 'calculators/bbt_mapper.dart';
import 'cycle_calculator.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';


export 'models/trends.dart';

/// A Facade class responsible for aggregating statistical and predictive data.
/// 
/// [TrendsCalculator] coordinates multiple specialized calculators to produce
/// a unified [TrendData] object. This allows the presentation layer to access
/// complex derived data (like predictions and BBT history) through a single entry point.
class TrendsCalculator {
  /// Aggregates all necessary trend data from the provided logs.
  /// 
  /// This method performs the following:
  /// 1. Calculates historical averages (cycle length, period duration).
  /// 2. Performs period prediction using [CycleCalculator].
  /// 3. Projects fertility windows using the [PredictionEngine].
  /// 4. Analyzes symptom frequency and mood history via [SymptomAnalyzer].
  /// 5. Maps temperature data relative to cycle boundaries via [BbtMapper].
  /// 
  /// Returns a [TrendData] object containing the comprehensive analysis.
  static TrendData calculateTrends(List<CycleLog> cycleLogs, List<SymptomLog> symptomLogs) {
    // 1. Historical Statistics
    final avgCycleLength = CycleStatsCalculator.calculateAverageCycleLength(cycleLogs);
    final avgPeriodDuration = CycleStatsCalculator.calculateAveragePeriodDuration(cycleLogs);
    
    // 2. Predictive Analysis
    // The [CycleCalculator] is sophisticated, supporting BBT-confirmed ovulation logic.
    final nextPeriod = CycleCalculator.predictNextPeriod(cycleLogs, symptomLogs);
    final fertility = PredictionEngine.predictFertilityWindow(nextPeriod);

    // 3. Behavioral and Physiological Analysis
    return TrendData(
      averageCycleLength: avgCycleLength,
      averagePeriodDuration: avgPeriodDuration,
      topSymptoms: SymptomAnalyzer.calculateTopSymptoms(symptomLogs),
      moodHistory: SymptomAnalyzer.getMoodHistory(symptomLogs),
      bbtHistory: BbtMapper.getBbtHistoryForCurrentCycle(cycleLogs, symptomLogs),
      predictedNextPeriod: nextPeriod,
      predictedFertilityDates: fertility,
    );
  }
}
