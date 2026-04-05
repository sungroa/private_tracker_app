import '../../domain/models/cycle_log.dart';
import '../../domain/repositories/cycle_log_repository.dart';
import '../storage/encrypted_storage_service.dart';

class CycleLogRepositoryImpl implements CycleLogRepository {
  final EncryptedStorageService _storageService;

  CycleLogRepositoryImpl(this._storageService);

  @override
  List<CycleEvent> getCycleEvents() {
    return _storageService.getCycleEvents();
  }

  @override
  Future<void> addCycleEvent(CycleEvent event) async {
    await _storageService.saveCycleEvent(event);
  }

  @override
  Future<void> updateCycleEvent(CycleEvent event) async {
    await _storageService.saveCycleEvent(event);
  }

  @override
  Future<void> deleteCycleEvent(String id) async {
    await _storageService.deleteCycleEvent(id);
  }
}
