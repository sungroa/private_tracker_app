import '../../domain/models/symptom_log.dart';
import '../../domain/repositories/symptom_log_repository.dart';
import '../storage/data_sources/symptom_data_source.dart';

/// Implementation of [SymptomLogRepository] using Hive.
/// 
/// 🏛️ **Architecture**: Mediates between the presentation layer (via Use Cases)
/// and the high-performance Hive data store. It ensures all data retrieval
/// is asynchronous to maintain UI responsiveness.
class SymptomLogRepositoryImpl implements SymptomLogRepository {
  final SymptomDataSource _dataSource;

  SymptomLogRepositoryImpl(this._dataSource);

  @override
  Future<List<SymptomLog>> getSymptomLogs() async {
    return _dataSource.getSymptomLogs();
  }

  @override
  Future<List<SymptomLog>> getSymptomLogsForMonth(DateTime month) async {
    return _dataSource.getSymptomLogsForMonth(month);
  }

  @override
  Future<void> addSymptomLog(SymptomLog log) async {
    await _dataSource.saveSymptomLog(log);
  }

  @override
  Future<void> updateSymptomLog(SymptomLog log) async {
    await _dataSource.saveSymptomLog(log);
  }

  @override
  Future<void> deleteSymptomLog(String id) async {
    await _dataSource.deleteSymptomLog(id);
  }
}
