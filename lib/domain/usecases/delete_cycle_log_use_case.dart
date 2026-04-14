import '../repositories/cycle_log_repository.dart';

/// Use case for permanently removing a menstruation cycle record.
/// 
/// 🎯 **Purpose**: Ensures that deletion logic is consistent and called via 
/// the domain layer.
/// 
/// 🧩 **Dependencies**:
/// - [CycleLogRepository]: Abstract interface for cycle data persistence.
/// 
/// ⚡ **Execution**: Runs in the foreground.
class DeleteCycleLogUseCase {
  final CycleLogRepository _repository;

  DeleteCycleLogUseCase(this._repository);

  /// Deletes the cycle log with the specified [id].
  Future<void> execute(String id) async {
    await _repository.deleteCycleLog(id);
  }
}
