import '../models/symptom_log.dart';
import '../repositories/symptom_log_repository.dart';

/// Use case for retrieving the historical record of symptoms and moods.
///
/// 🎯 **Purpose**: Provides the data source for trend analysis and historical
/// list views within the presentation layer.
///
/// 🧩 **Dependencies**:
/// - [SymptomLogRepository]: Repository for managing symptom logs.
///
/// ⚡ **Execution**: Runs in the foreground.
class GetSymptomLogsUseCase {
  GetSymptomLogsUseCase(this._repository);
  final SymptomLogRepository _repository;

  Future<List<SymptomLog>> execute() async {
    return await _repository.getSymptomLogs();
  }
}
