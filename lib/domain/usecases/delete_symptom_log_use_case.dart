import '../repositories/symptom_log_repository.dart';

/// Use case for permanently removing a symptom or mood record.
/// 
/// 🎯 **Purpose**: Decouples the presentation layer from the repository and 
/// ensures consistent deletion logic within the domain boundaries.
/// 
/// 🧩 **Dependencies**:
/// - [SymptomLogRepository]: Repository for managing symptom logs.
/// 
/// ⚡ **Execution**: Runs in the foreground.
class DeleteSymptomLogUseCase {
  final SymptomLogRepository _repository;

  DeleteSymptomLogUseCase(this._repository);

  Future<void> execute(String id) async {
    await _repository.deleteSymptomLog(id);
  }
}
