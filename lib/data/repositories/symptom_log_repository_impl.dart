import '../../domain/models/symptom_log.dart';
import '../../domain/repositories/symptom_log_repository.dart';
import '../storage/data_sources/symptom_data_source.dart';

class SymptomLogRepositoryImpl implements SymptomLogRepository {
  final SymptomDataSource _dataSource;

  SymptomLogRepositoryImpl(this._dataSource);

  @override
  List<SymptomLog> getSymptomLogs() {
    return _dataSource.getAllSymptomLogs();
  }

  @override
  List<SymptomLog> getSymptomLogsForMonth(DateTime month) {
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
