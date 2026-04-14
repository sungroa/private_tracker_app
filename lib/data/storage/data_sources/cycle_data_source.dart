import 'package:private_tracker_app/core/registry/hive_registry.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import '../local_database_manager.dart';
import '../hive_dtos.dart';
import '../model_mapper.dart';
import 'local_data_source.dart';

/// Data source for [CycleLog] persistence using Hive DTOs.
class CycleDataSource extends LocalDataSource<CycleLogDto> {
  CycleDataSource(LocalDatabaseManager dbManager)
      : super(dbManager, HiveRegistry.cycleLogBox);

  /// Retrieves and converts all logs to domain models asynchronously.
  Future<List<CycleLog>> getCycleLogs() async {
    final dtos = await getAll();
    // Sort by start date (newest first)
    dtos.sort((a, b) => b.startDate.compareTo(a.startDate));
    return dtos.map((dto) => ModelMapper.cycleLogFromDto(dto)).toList();
  }

  /// Persists a domain model as a storage DTO.
  /// 
  /// Business metadata (like timestamps) must be set in the Domain layer 
  /// before calling this method.
  Future<void> saveCycleLog(CycleLog event) {
    return put(event.id, ModelMapper.cycleLogToDto(event));
  }

  /// Deletes a log entry by ID.
  Future<void> deleteCycleLog(String id) {
    return delete(id);
  }
}
