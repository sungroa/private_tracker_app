import 'package:flutter/foundation.dart';
import '../../data/storage/encrypted_storage_service.dart';
import '../../data/storage/secure_key_storage.dart';
import '../../data/storage/backup_restore_service.dart';
import '../../data/storage/local_database_manager.dart';
import '../models/cycle_log.dart';
import '../models/symptom_log.dart';
import '../models/custom_tag.dart';
import '../services/cloud_sync_interface.dart';

/// Represents the data returned from the background merge isolate.
class MergedData {
  final List<CycleLog> cycleLogs;
  final List<SymptomLog> symptomLogs;
  final List<CustomTag> customTags;

  MergedData({
    required this.cycleLogs,
    required this.symptomLogs,
    required this.customTags,
  });
}

/// Orchestrates the synchronization process with record-level LWW conflict resolution.
class SyncDataUseCase {
  final CloudSyncInterface _cloudSync;
  final EncryptedStorageService _storage;
  final SecureKeyStorage _keyStorage;
  final BackupRestoreService _backupService;
  final LocalDatabaseManager _dbManager;

  SyncDataUseCase({
    required CloudSyncInterface cloudSync,
    required EncryptedStorageService storage,
    required SecureKeyStorage keyStorage,
    required BackupRestoreService backupService,
    required LocalDatabaseManager dbManager,
  })  : _cloudSync = cloudSync,
        _storage = storage,
        _keyStorage = keyStorage,
        _backupService = backupService,
        _dbManager = dbManager;

  /// Executes the synchronization cycle.
  /// 
  /// Returns `true` if changes were applied to the local database.
  Future<bool> execute() async {
    try {
      await _cloudSync.authenticate();

      final cloudChecksum = await _cloudSync.fetchLatestCloudChecksum();
      final metaBox = _dbManager.getBox<String>(LocalDatabaseManager.metaBox);
      
      final lastSyncChecksum = metaBox.get(LocalDatabaseManager.lastSyncChecksumKey);
      final lastLocalModified = metaBox.get(LocalDatabaseManager.lastLocalModifiedKey);

      // 1. Check if we need to do anything at all
      if (cloudChecksum == null) {
        // First time syncing: Upload local data to cloud
        await _performFullUpload();
        return false;
      }

      if (cloudChecksum == lastSyncChecksum && lastLocalModified == null) {
        // Nothing changed on either side
        debugPrint('SyncDataUseCase: No changes detected on cloud or local.');
        return false;
      }

      // 2. Download cloud data
      final cloudKey = await _keyStorage.getOrCreateCloudSyncKey();
      final cloudBackupFile = await _cloudSync.downloadEncryptedBackup();
      final cloudDataMap = await _backupService.importBackupWithKey(cloudBackupFile, cloudKey);

      // 3. Prepare local data
      final localDataMap = _storage.getAllDataAsMap();

      // 4. Perform merge on background isolate using LWW
      final mergedData = await compute(_mergeDataWorker, {
        'local': localDataMap,
        'cloud': cloudDataMap,
      });

      // 5. Apply changes locally
      await _storage.persistMergedData(
        cycleLogs: mergedData.cycleLogs,
        symptomLogs: mergedData.symptomLogs,
        customTags: mergedData.customTags,
      );

      // 6. Final upload to ensure cloud has the merged state
      await _performFullUpload();

      return true;
    } catch (e) {
      debugPrint('SyncDataUseCase: Error during sync: $e');
      rethrow;
    }
  }

  Future<void> _performFullUpload() async {
    final cloudKey = await _keyStorage.getOrCreateCloudSyncKey();
    final file = await _storage.exportCloudBackup(cloudKey);
    
    // Generate a new checksum based on current time
    final checksum = DateTime.now().millisecondsSinceEpoch.toString();
    await _cloudSync.uploadEncryptedBackup(file, checksum);

    // Update sync state
    final metaBox = _dbManager.getBox<String>(LocalDatabaseManager.metaBox);
    await metaBox.put(LocalDatabaseManager.lastSyncChecksumKey, checksum);
    // Reset local modified flag since we are now in sync with cloud
    await metaBox.delete(LocalDatabaseManager.lastLocalModifiedKey);
    
    debugPrint('SyncDataUseCase: Upload complete. Checksum: $checksum');
  }
}

/// Background worker for merging data using Last-Write-Wins (LWW).
/// 
/// This function runs on a separate isolate. 
/// It takes raw Maps and returns a [MergedData] object.
MergedData _mergeDataWorker(Map<String, dynamic> params) {
  final local = params['local'] as Map<String, dynamic>;
  final cloud = params['cloud'] as Map<String, dynamic>;

  // Merge Custom Tags
  final mergedTags = _mergeRecords<CustomTag>(
    local: (local['customTags'] as List).map((m) => CustomTag.fromMap(Map<String, dynamic>.from(m))).toList(),
    cloud: (cloud['customTags'] as List).map((m) => CustomTag.fromMap(Map<String, dynamic>.from(m))).toList(),
    getUpdatedAt: (t) => t.updatedAt,
    getId: (t) => t.id,
  );

  // Merge Cycle Logs
  final mergedCycles = _mergeRecords<CycleLog>(
    local: (local['cycleLogs'] as List).map((m) => CycleLog.fromMap(Map<String, dynamic>.from(m))).toList(),
    cloud: (cloud['cycleLogs'] as List).map((m) => CycleLog.fromMap(Map<String, dynamic>.from(m))).toList(),
    getUpdatedAt: (c) => c.updatedAt,
    getId: (c) => c.id,
  );

  // Merge Symptom Logs
  final mergedSymptoms = _mergeRecords<SymptomLog>(
    local: (local['symptomLogs'] as List).map((m) => SymptomLog.fromMap(Map<String, dynamic>.from(m))).toList(),
    cloud: (cloud['symptomLogs'] as List).map((m) => SymptomLog.fromMap(Map<String, dynamic>.from(m))).toList(),
    getUpdatedAt: (s) => s.updatedAt,
    getId: (s) => s.id,
  );

  return MergedData(
    cycleLogs: mergedCycles,
    symptomLogs: mergedSymptoms,
    customTags: mergedTags,
  );
}

/// Helper to merge two lists of records using LWW based on updatedAt.
List<T> _mergeRecords<T>({
  required List<T> local,
  required List<T> cloud,
  required DateTime Function(T) getUpdatedAt,
  required String Function(T) getId,
}) {
  final Map<String, T> merged = {};

  // Initialize with cloud records
  for (var record in cloud) {
    merged[getId(record)] = record;
  }

  // Iterate local records. If local is newer, it wins.
  for (var localRecord in local) {
    final id = getId(localRecord);
    final cloudRecord = merged[id];

    if (cloudRecord == null) {
      // Local record doesn't exist in cloud: keep local
      merged[id] = localRecord;
    } else {
      final localUpdate = getUpdatedAt(localRecord);
      final cloudUpdate = getUpdatedAt(cloudRecord);

      if (localUpdate.isAfter(cloudUpdate)) {
        merged[id] = localRecord;
      }
      // Else: Cloud record wins (already in map)
    }
  }

  return merged.values.toList();
}
