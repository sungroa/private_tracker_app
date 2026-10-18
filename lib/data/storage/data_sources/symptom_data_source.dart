import 'package:private_tracker_app/core/registry/hive_registry.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';

import '../hive_dtos.dart';
import '../local_database_manager.dart';
import '../model_mapper.dart';
import 'local_data_source.dart';

class SymptomDataSource extends LocalDataSource<SymptomLogDto> {
  SymptomDataSource(LocalDatabaseManager dbManager) : super(dbManager, HiveRegistry.symptomLogBox);

  Future<List<SymptomLog>> getSymptomLogsForMonth(DateTime month) async {
    final dtos = await getAll();
    return dtos
        .where((dto) => dto.date.year == month.year && dto.date.month == month.month)
        .map((dto) => ModelMapper.symptomLogFromDto(dto))
        .toList();
  }

  Future<List<SymptomLog>> getSymptomLogs() async {
    final dtos = await getAll();
    return dtos.map((dto) => ModelMapper.symptomLogFromDto(dto)).toList();
  }

  Future<void> saveSymptomLog(SymptomLog log) {
    // Ensure accurate persistence metadata
    final updatedLog = log.copyWith(updatedAt: DateTime.now());
    return put(updatedLog.id, ModelMapper.symptomLogToDto(updatedLog));
  }

  Future<void> deleteSymptomLog(String id) {
    return delete(id);
  }
}
