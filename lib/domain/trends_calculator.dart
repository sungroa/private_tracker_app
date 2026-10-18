import 'package:private_tracker_app/domain/models/symptom_log.dart';

import 'calculators/bbt_mapper.dart';
import 'calculators/cycle_stats_calculator.dart';
import 'calculators/prediction_engine.dart';
import 'calculators/symptom_analyzer.dart';
import 'cycle_calculator.dart';
import 'models/cycle_log.dart';
import 'models/trends.dart';

export 'models/trends.dart';

/// A Facade class responsible for aggregating statistical and predictive data.
///
/// [TrendsCalculator] coordinates multiple specialized calculators to produce
/// a unified [TrendData] object. This allows the presentation layer to access
/// complex derived data (like predictions and BBT history) through a single entry point.
class TrendsCalculator {
  TrendsCalculator(this._cycleCalculator);
  final CycleCalculator _cycleCalculator;

  /// Aggregates all necessary trend data from the provided logs.
  ///
  /// This method performs the following:
  /// 1. Calculates historical averages (cycle length, period duration).
  /// 2. Projects up to 4 future period dates using [CycleCalculator.predictFuturePeriods].
  ///    The count is adaptive — see [CycleCalculator._adaptiveProjectionCount].
  /// 3. Merges fertility windows for all projected cycles via [PredictionEngine.predictAllFertilityWindows].
  /// 4. Analyzes symptom frequency and mood history via [SymptomAnalyzer].
  /// 5. Maps temperature data relative to cycle boundaries via [BbtMapper].
  ///
  /// Returns a [TrendData] object containing the comprehensive analysis.
  TrendData calculateTrends(List<CycleLog> cycleLogs, List<SymptomLog> symptomLogs) {
    // 1. Historical Statistics
    final avgCycleLength = CycleStatsCalculator.calculateAverageCycleLength(cycleLogs);
    final avgPeriodDuration = CycleStatsCalculator.calculateAveragePeriodDuration(cycleLogs);

    // 2. Multi-Cycle Predictive Analysis
    // Adaptively projects 1–4 future cycles depending on available history.
    final periodStarts = _cycleCalculator.predictFuturePeriods(cycleLogs, symptomLogs: symptomLogs);
    final fertilityDates = PredictionEngine.predictAllFertilityWindows(periodStarts);

    // 3. Behavioral and Physiological Analysis
    return TrendData(
      averageCycleLength: avgCycleLength,
      averagePeriodDuration: avgPeriodDuration,
      topSymptoms: SymptomAnalyzer.calculateTopSymptoms(symptomLogs),
      moodHistory: SymptomAnalyzer.getMoodHistory(symptomLogs),
      bbtHistory: BbtMapper.getBbtHistoryForCurrentCycle(cycleLogs, symptomLogs),
      predictedPeriodStarts: periodStarts,
      predictedFertilityDates: fertilityDates,
    );
  }
}
