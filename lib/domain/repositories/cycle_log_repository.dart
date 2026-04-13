import '../models/cycle_log.dart';

/// Repository interface for managing [CycleLog] domain objects.
abstract class CycleLogRepository {
  /// Retrieves all recorded cycle logs from persistent storage.
  List<CycleLog> getCycleLogs();

  /// Adds a new cycle log entry.
  Future<void> addCycleLog(CycleLog event);

  /// Updates an existing cycle log entry.
  Future<void> updateCycleLog(CycleLog event);

  /// Removes a cycle log entry by its unique identifier.
  Future<void> deleteCycleLog(String id);
}
