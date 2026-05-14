import 'dart:isolate';
import '../models/cycle_log.dart';
import '../models/symptom_log.dart';
import '../repositories/cycle_log_repository.dart';
import '../repositories/symptom_log_repository.dart';
import '../trends_calculator.dart';

/// Represents the analyzed state of cycle data.
/// 
/// [AnalysedCycles] is a pure domain response model. Presentation-specific 
/// optimizations like calendar mapping have been moved to the presentation layer.
class AnalysedCycles {
  final List<CycleLog> logs;
  final TrendData trends;

  AnalysedCycles({
    required this.logs,
    required this.trends,
  });
}

/// Use case for retrieving and analyzing cycle logs.
/// 
/// [GetCycleLogsUseCase] ensures "Technical Excellence" by:
/// 1. Orchestrating asynchronous data fetching.
/// 2. Offloading CPU-intensive calculations to background Isolates.
/// 3. Maintaining strict layer separation.
class GetCycleLogsUseCase {
  final CycleLogRepository _cycleRepository;
  final SymptomLogRepository _symptomRepository;

  GetCycleLogsUseCase(this._cycleRepository, this._symptomRepository);

  /// Executes the use case asynchronously.
  /// 
  /// Returns an [AnalysedCycles] object containing processed data.
  Future<AnalysedCycles> execute() async {
    // 1. Concurrent fetching from repositories
    final results = await Future.wait([
      _cycleRepository.getCycleLogs(),
      _symptomRepository.getSymptomLogs(),
    ]);

    final logs = results[0] as List<CycleLog>;
    final symptomLogs = results[1] as List<SymptomLog>;

    // 2. Perform heavy calculations in a background Isolate (W3)
    // This prevents UI jank regardless of the amount of historical data.
    final trends = await Isolate.run(() {
      return TrendsCalculator.calculateTrends(logs, symptomLogs);
    });

    return AnalysedCycles(
      logs: logs,
      trends: trends,
    );
  }
}
