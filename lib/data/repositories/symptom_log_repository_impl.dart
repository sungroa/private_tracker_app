import '../../domain/models/cycle_log.dart';
import '../../domain/repositories/symptom_log_repository.dart';
import '../storage/encrypted_storage_service.dart';

class SymptomLogRepositoryImpl implements SymptomLogRepository {
  final EncryptedStorageService _storageService;

  SymptomLogRepositoryImpl(this._storageService);

  @override
  List<SymptomLog> getSymptomLogs() {
    return _storageService.getSymptomLogs();
  }

  @override
  List<SymptomLog> getSymptomLogsForMonth(DateTime month) {
    return _storageService.getSymptomLogsForMonth(month);
  }

  @override
  Future<void> addSymptomLog(SymptomLog log) async {
    await _storageService.saveSymptomLog(log);
  }

  @override
  Future<void> updateSymptomEvent(SymptomLog event) async {
    await _storageService.saveSymptomLog(event);
  }

  @override
  Future<void> deleteSymptomEvent(String id) async {
    await _storageService.deleteSymptomLog(id);
  }
}
