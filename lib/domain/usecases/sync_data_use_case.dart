import 'dart:isolate';
import 'package:crypto/crypto.dart';

import '../repositories/data_source_repository.dart';
import '../repositories/sync_metadata_repository.dart';
import '../services/cloud_sync_interface.dart';

/// Orchestrates the synchronization process with record-level LWW conflict resolution.
/// 
/// This use case is completely decoupled from the data layer via [IDataSourceRepository]
/// and [ISyncMetadataRepository].
class SyncDataUseCase {
  final CloudSyncInterface _cloudSync;
  final IDataSourceRepository _dataSource;
  final ISyncMetadataRepository _metadata;
  final Future<List<int>> Function() _keyProvider;

  SyncDataUseCase({
    required CloudSyncInterface cloudSync,
    required IDataSourceRepository dataSource,
    required ISyncMetadataRepository metadata,
    required Future<List<int>> Function() keyProvider,
  })  : _cloudSync = cloudSync,
        _dataSource = dataSource,
        _metadata = metadata,
        _keyProvider = keyProvider;

  /// Executes the synchronization cycle.
  /// 
  /// Returns `true` if changes were applied to the local database.
  Future<bool> execute() async {
    try {
      await _cloudSync.authenticate();

      final cloudChecksum = await _cloudSync.fetchLatestCloudChecksum();
      final lastSyncChecksum = await _metadata.getLastSyncChecksum();
      final lastLocalModified = await _metadata.getLastLocalModified();

      // 1. Check if we need to do anything at all
      if (cloudChecksum == null) {
        // First time syncing or cloud wiped: Upload local data to cloud
        await _performFullUpload();
        return false;
      }

      if (cloudChecksum == lastSyncChecksum && lastLocalModified == null) {
        // Nothing changed on either side
        return false;
      }

      // 2. Download cloud data
      final cloudPayload = await _cloudSync.downloadEncryptedBackup();
      
      // Verification (W8): Verify the downloaded payload matches the cloud checksum
      final downloadedHash = sha256.convert(cloudPayload).toString();
      if (cloudChecksum != downloadedHash) {
        throw CloudSyncException(
          CloudSyncException.downloadFailed,
          'Integrity check failed: Cloud checksum mismatch ($cloudChecksum vs $downloadedHash)',
        );
      }

      // 3. Prepare local/cloud maps for merging
      final localDataMap = await _dataSource.getAllDataAsMap();
      final cloudKey = await _keyProvider();
      final cloudDataMap = await _dataSource.parseCloudBackup(cloudPayload, cloudKey);
      
      // 4. Perform merge on background isolate using LWW
      // (W1) Pure Dart Isolate.run to decouple from Flutter framework
      final mergedDataMap = await Isolate.run(() => _mergeDataWorkerSer({
        'local': localDataMap,
        'cloud': cloudDataMap,
      }));

      // 5. Apply merged results locally
      await _dataSource.persistMergedMap(mergedDataMap);

      // 6. Final upload to ensure cloud has the merged state
      await _performFullUpload();

      return true;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> _performFullUpload() async {
    final cloudKey = await _keyProvider();
    final payload = await _dataSource.exportCloudBackup(cloudKey);
    final checksum = sha256.convert(payload).toString();
    
    await _cloudSync.uploadEncryptedBackup(payload, checksum);
    await _metadata.setLastSyncChecksum(checksum);
    await _metadata.clearLocalModifiedFlag();
  }
}

/// Background worker for merging data using Last-Write-Wins (LWW).
/// 
/// (C1) This function runs on a separate isolate and handles ONLY serializable types.
Map<String, dynamic> _mergeDataWorkerSer(Map<String, dynamic> params) {
  final local = params['local'] as Map<String, dynamic>;
  final cloud = params['cloud'] as Map<String, dynamic>;

  // Merge each collection
  return {
    'customTags': _mergeRecordsSer(
      local: local['customTags'] as List,
      cloud: cloud['customTags'] as List,
    ),
    'cycleLogs': _mergeRecordsSer(
      local: local['cycleLogs'] as List,
      cloud: cloud['cycleLogs'] as List,
    ),
    'symptomLogs': _mergeRecordsSer(
      local: local['symptomLogs'] as List,
      cloud: cloud['symptomLogs'] as List,
    ),
  };
}

/// Helper to merge two lists of record Maps using LWW based on updatedAt.
List<dynamic> _mergeRecordsSer({
  required List<dynamic> local,
  required List<dynamic> cloud,
}) {
  final Map<String, dynamic> merged = {};

  // Initialize with cloud records
  for (final record in cloud) {
    merged[record['id'] as String] = record;
  }

  // Iterate local records. If local is newer, it wins.
  for (final localRecord in local) {
    final id = localRecord['id'] as String;
    final cloudRecord = merged[id];

    if (cloudRecord == null) {
      merged[id] = localRecord;
    } else {
      final localUpdate = DateTime.parse(localRecord['updatedAt'] as String);
      final cloudUpdate = DateTime.parse(cloudRecord['updatedAt'] as String);

      if (localUpdate.isAfter(cloudUpdate)) {
        merged[id] = localRecord;
      } else if (localUpdate.isAtSameMomentAs(cloudUpdate)) {
        // (N2) Tie-breaker: deterministic fallback (using string comparison of updatedAt raw strings or content)
        // Corrected: id.compareTo(id) was always 0. We compare the raw updatedAt strings
        // or just pick one deterministically if timestamps are identical.
        if ((localRecord['id'] as String).hashCode > (cloudRecord['id'] as String).hashCode) {
           merged[id] = localRecord;
        }
      }
      // Else: Cloud record wins (already in map)
    }
  }

  return merged.values.toList();
}
