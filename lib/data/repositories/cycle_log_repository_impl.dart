import '../../domain/models/cycle_log.dart';
import '../../domain/repositories/cycle_log_repository.dart';
import '../storage/data_sources/cycle_data_source.dart';

/// Implementation of [CycleLogRepository] using Hive as the persistence layer.
///
/// 🏛️ **Architecture**: This class implements the Repository Pattern, acting
/// as a mediator between the Domain Use Cases and the low-level [CycleDataSource].
/// It ensures that all data access is asynchronous and follows the domain
/// interface contract.
class CycleLogRepositoryImpl implements CycleLogRepository {
  CycleLogRepositoryImpl(this._dataSource);
  final CycleDataSource _dataSource;

  @override
  Future<List<CycleLog>> getCycleLogs() async {
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
