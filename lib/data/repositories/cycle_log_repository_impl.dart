import '../../domain/models/cycle_log.dart';
import '../../domain/repositories/cycle_log_repository.dart';
import '../storage/encrypted_storage_service.dart';

class CycleLogRepositoryImpl implements CycleLogRepository {
  final EncryptedStorageService _storageService;

  CycleLogRepositoryImpl(this._storageService);

  @override
  List<CycleLog> getCycleLogs() {
    return _storageService.getCycleLogs();
  }

  @override
  Future<void> addCycleLog(CycleLog log) async {
    await _storageService.saveCycleLog(log);
  }

  @override
  Future<void> updateCycleEvent(CycleLog event) async {
    await _storageService.saveCycleLog(event);
  }

  @override
  Future<void> deleteCycleEvent(String id) async {
    await _storageService.deleteCycleLog(id);
  }
}
