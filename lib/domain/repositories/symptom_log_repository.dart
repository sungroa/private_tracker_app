import 'package:private_tracker_app/domain/models/symptom_log.dart';


/// Repository interface for managing [SymptomLog] domain objects.
abstract class SymptomLogRepository {
  /// Retrieves all recorded symptom logs from persistent storage.
  Future<List<SymptomLog>> getSymptomLogs();

  /// Retrieves symptom logs filtered by a specific month.
  Future<List<SymptomLog>> getSymptomLogsForMonth(DateTime month);

  /// Adds a new symptom log entry.
  Future<void> addSymptomLog(SymptomLog log);

  /// Updates an existing symptom log entry.
  Future<void> updateSymptomLog(SymptomLog log);

  /// Removes a symptom log entry by its unique identifier.
  Future<void> deleteSymptomLog(String id);
}
