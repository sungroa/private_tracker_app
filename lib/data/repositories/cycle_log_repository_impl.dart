import '../../domain/models/cycle_log.dart';
import '../../domain/repositories/cycle_log_repository.dart';
import '../storage/data_sources/cycle_data_source.dart';

class CycleLogRepositoryImpl implements CycleLogRepository {
  final CycleDataSource _dataSource;

  CycleLogRepositoryImpl(this._dataSource);

  @override
  List<CycleEvent> getCycleEvents() {
    return _dataSource.getCycleEvents();
  }

  @override
  Future<void> addCycleEvent(CycleEvent event) async {
    await _dataSource.saveCycleEvent(event);
  }

  @override
  Future<void> updateCycleEvent(CycleEvent event) async {
    await _dataSource.saveCycleEvent(event);
  }

  @override
  Future<void> deleteCycleEvent(String id) async {
    await _dataSource.deleteCycleEvent(id);
  }
}
