import '../models/cycle_log.dart';
import '../repositories/cycle_log_repository.dart';

/// Use case for creating or updating a cycle log entry.
/// 
/// 🎯 **Purpose**: This use case centralizes the persistence logic for cycle data,
/// ensuring that domain-critical metadata (like `updatedAt`) is injected at
/// the boundary before data enters the repository.
/// 
/// 🧩 **Dependencies**:
/// - [CycleLogRepository]: Abstract interface for cycle data persistence.
/// 
/// ⚡ **Execution**: Runs in the foreground; awaiting individual repository operations.
class SaveCycleLogUseCase {
  final CycleLogRepository _repository;

  SaveCycleLogUseCase(this._repository);

  /// Executes the save operation.
  /// 
  /// Injects a fresh [DateTime.now()] into the [updatedAt] field of the [log]
  /// to maintain the integrity of the LWW (Last-Write-Wins) sync protocol.
  Future<void> execute(CycleLog log) async {
    final updatedLog = log.copyWith(updatedAt: DateTime.now());
    
    // Check if it's a new log or an update (though we use same repo method for both often)
    // Here we just delegate to the repository which handles the persistence logic.
    await _repository.updateCycleLog(updatedLog);
  }
}
