import '../../../domain/models/cycle_log.dart';
import '../local_database_manager.dart';
import '../hive_dtos.dart';
import 'local_data_source.dart';

class CycleDataSource extends LocalDataSource<CycleLogDto> {
  CycleDataSource(LocalDatabaseManager dbManager) : super(dbManager, LocalDatabaseManager.cycleLogBox);

  List<CycleLog> getCycleLogs() {
    final dtos = getAll();
    dtos.sort((a, b) => b.startDate.compareTo(a.startDate)); // Newest first
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  Future<void> saveCycleLog(CycleLog event) {
    return put(event.id, CycleLogDto.fromDomain(event));
  }

  Future<void> deleteCycleLog(String id) {
    return delete(id);
  }
}
