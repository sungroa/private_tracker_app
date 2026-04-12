import '../../domain/models/cycle_log.dart';
import '../../domain/repositories/cycle_log_repository.dart';
import '../storage/data_sources/cycle_data_source.dart';

class CycleLogRepositoryImpl implements CycleLogRepository {
  final CycleDataSource _dataSource;

  CycleLogRepositoryImpl(this._dataSource);

  @override
  List<CycleLog> getCycleLogs() {
    return _dataSource.getCycleLogs();
  }

  @override
  Future<void> addCycleLog(CycleLog event) async {
    await _dataSource.saveCycleLog(event);
  }

  @override
  Future<void> updateCycleLog(CycleLog event) async {
    await _dataSource.saveCycleLog(event);
  }

  @override
  Future<void> deleteCycleLog(String id) async {
    await _dataSource.deleteCycleLog(id);
  }
}
