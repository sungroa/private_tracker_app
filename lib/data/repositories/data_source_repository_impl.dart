import 'dart:typed_data';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/symptom_log.dart';
import '../../domain/models/custom_tag.dart';
import '../../domain/repositories/data_source_repository.dart';
import '../storage/encrypted_storage_service.dart';
import '../storage/backup_orchestrator.dart';

class DataSourceRepositoryImpl implements IDataSourceRepository {
  final EncryptedStorageService _storageService;
  final BackupOrchestrator _backupOrchestrator;

  DataSourceRepositoryImpl(this._storageService, this._backupOrchestrator);

  @override
  Map<String, dynamic> getAllDataAsMap() {
    return _storageService.getAllDataAsMap();
  }

  @override
  Future<void> persistMergedData({
    required List<CycleLog> cycleLogs,
    required List<SymptomLog> symptomLogs,
    required List<CustomTag> customTags,
  }) async {
    await _storageService.persistMergedData(
      cycleLogs: cycleLogs,
      symptomLogs: symptomLogs,
      customTags: customTags,
    );
  }

  @override
  Future<void> persistMergedMap(Map<String, dynamic> mergedData) async {
    await _backupOrchestrator.persistMergedMap(mergedData);
  }

  @override
  Future<Uint8List> exportCloudBackup(List<int> cloudKey) async {
    return await _backupOrchestrator.exportCloudBackup(cloudKey);
  }

  @override
  Future<Map<String, dynamic>> parseCloudBackup(Uint8List payload, List<int> cloudKey) async {
    return await _backupOrchestrator.importBackupWithKey(payload, cloudKey);
  }
}
