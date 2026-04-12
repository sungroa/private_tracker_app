import '../../../domain/models/symptom_log.dart';
import '../local_database_manager.dart';
import '../hive_dtos.dart';
import 'local_data_source.dart';

class SymptomDataSource extends LocalDataSource<SymptomLogDto> {
  SymptomDataSource(LocalDatabaseManager dbManager) : super(dbManager, LocalDatabaseManager.symptomLogBox);

  List<SymptomLog> getSymptomLogsForMonth(DateTime month) {
    return values
        .where((dto) => dto.date.year == month.year && dto.date.month == month.month)
        .map((dto) => dto.toDomain())
        .toList();
  }

  List<SymptomLog> getAllSymptomLogs() {
    return values.map((dto) => dto.toDomain()).toList();
  }

  Future<void> saveSymptomLog(SymptomLog log) {
    final updatedLog = log.copyWith(updatedAt: DateTime.now());
    return put(updatedLog.id, SymptomLogDto.fromDomain(updatedLog));
  }

  Future<void> deleteSymptomLog(String id) {
    return delete(id);
  }
}
