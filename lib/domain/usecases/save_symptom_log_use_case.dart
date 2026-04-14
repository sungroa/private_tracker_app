import '../models/symptom_log.dart';
import '../repositories/symptom_log_repository.dart';

/// Use case for creating or updating a symptom/mood log entry.
/// 
/// 🎯 **Purpose**: This use case ensures that all symptom data entering the 
/// persistence layer is correctly timestamped with [updatedAt] for synchronization 
/// integrity.
/// 
/// 🧩 **Dependencies**:
/// - [SymptomLogRepository]: Repository for managing symptom logs.
/// 
/// ⚡ **Execution**: Runs in the foreground.
class SaveSymptomLogUseCase {
  final SymptomLogRepository _repository;

  SaveSymptomLogUseCase(this._repository);

  /// Saves the [log] and ensures audit metadata is maintained.
  Future<void> execute(SymptomLog log) async {
    final updatedLog = log.copyWith(updatedAt: DateTime.now());
    await _repository.updateSymptomLog(updatedLog);
  }
}
