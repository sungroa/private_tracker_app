import 'models/cycle_log.dart';
import 'models/trends.dart';
import 'calculators/cycle_stats_calculator.dart';
import 'calculators/prediction_engine.dart';
import 'calculators/symptom_analyzer.dart';
import 'calculators/bbt_mapper.dart';
import 'cycle_calculator.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';


export 'models/trends.dart';

class TrendsCalculator {
  /// Aggregates all necessary trend data from the provided logs.
  /// This acting as a Facade to specialized calculators.
  static TrendData calculateTrends(List<CycleEvent> cycleLogs, List<SymptomLog> symptomLogs) {
    final avgCycleLength = CycleStatsCalculator.calculateAverageCycleLength(cycleLogs);
    final avgPeriodDuration = CycleStatsCalculator.calculateAveragePeriodDuration(cycleLogs);
    
    // Use the sophisticated CycleCalculator which supports BBT-confirmed ovulation
    final nextPeriod = CycleCalculator.predictNextPeriod(cycleLogs, symptomLogs);
    final fertility = PredictionEngine.predictFertilityWindow(nextPeriod);

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
