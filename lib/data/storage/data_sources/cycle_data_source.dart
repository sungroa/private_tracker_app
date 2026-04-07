import '../../../domain/models/cycle_log.dart';
import '../local_database_manager.dart';
import '../hive_dtos.dart';
import 'local_data_source.dart';

class CycleDataSource extends LocalDataSource<CycleEventDto> {
  CycleDataSource(LocalDatabaseManager dbManager) : super(dbManager, LocalDatabaseManager.cycleLogBox);

  List<CycleEvent> getCycleEvents() {
    final dtos = getAll();
    dtos.sort((a, b) => b.startDate.compareTo(a.startDate)); // Newest first
    return dtos.map((dto) => dto.sovereignty()).toList();
  }

  Future<void> saveCycleEvent(CycleEvent event) {
    return put(event.id, CycleEventDto.fromDomain(event));
  }

  Future<void> deleteCycleEvent(String id) {
    return delete(id);
  }
}
