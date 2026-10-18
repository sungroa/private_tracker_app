import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../core/utils/security_logger.dart';
import '../repositories/data_source_repository.dart';
import '../repositories/sync_metadata_repository.dart';
import '../services/cloud_sync_interface.dart';

/// Orchestrates the synchronization process with record-level LWW conflict resolution.
///
/// This use case is completely decoupled from the data layer via [IDataSourceRepository]
/// and [ISyncMetadataRepository].
class SyncDataUseCase {
  SyncDataUseCase({
    required this._cloudSync,
    required this._dataSource,
    required this._metadata,
    required this._keyProvider,
  });
  final CloudSyncInterface _cloudSync;
  final IDataSourceRepository _dataSource;
  final ISyncMetadataRepository _metadata;
  final Future<List<int>> Function() _keyProvider;

  /// Updates the local recovery salt.
  Future<void> setRecoverySalt(String salt) async {
    await _metadata.setRecoverySalt(salt);
  }

  /// Clears local sync metadata.
  Future<void> clearLocalMetadata() async {
    await _metadata.setLastSyncChecksum(null);
    await _metadata.setRecoverySalt(null);
  }

  /// Verifies that [key] can successfully decrypt [payload].
  ///
  /// Used as a proof-of-knowledge check during passphrase rotation — the caller
  /// must demonstrate they hold the current key before we allow a key change.
  /// Throws if the key is incorrect or the payload is corrupted.
  Future<void> verifyCloudDecrypt(Uint8List payload, List<int> key) async {
    // Attempt a full parse. If the key is wrong, parseCloudBackup throws an
    // integrity exception which propagates to the caller unchanged.
    await _dataSource.parseCloudBackup(payload, key);
  }

  /// Executes the synchronization cycle.
  ///
  /// Returns `true` if changes were applied to the local database.
  Future<bool> execute() async {
    String? currentCloudSalt;
    try {
      SecurityLogger.logInfo("Sync Cycle: Starting authentication phase...");
      await _cloudSync.authenticate();

      SecurityLogger.logInfo("Sync Cycle: Fetching latest cloud metadata...");
      final cloudMetadata = await _cloudSync.fetchLatestCloudMetadata();
      final cloudChecksum = cloudMetadata?['checksum'];
      currentCloudSalt = cloudMetadata?['recovery_salt'];

      // (W10) Recovery salt management
      final localSalt = await _metadata.getRecoverySalt();
      if (currentCloudSalt != null && localSalt == null) {
        SecurityLogger.logInfo("Sync Cycle: New cloud salt detected. Storing locally.");
        await _metadata.setRecoverySalt(currentCloudSalt);
      } else if (currentCloudSalt != null && localSalt != null && currentCloudSalt != localSalt) {
        SecurityLogger.logInfo(
          "Sync Cycle: Recovery salt mismatch detected. Triggering recovery prompt.",
        );
        throw CloudSyncException(
          CloudSyncException.recoveryRequired,
          "Recovery salt mismatch between local and cloud.",
        );
      }

      final lastSyncChecksum = await _metadata.getLastSyncChecksum();
      final lastLocalModified = await _metadata.getLastLocalModified();

      // 1. Check if we need to do anything at all
      if (cloudChecksum == null) {
        SecurityLogger.logInfo("Sync Cycle: No cloud backup found. Performing full upload.");
        await _performFullUpload();
        return false;
      }

      if (cloudChecksum == lastSyncChecksum && lastLocalModified == null) {
        SecurityLogger.logInfo("Sync Cycle: State is already up to date. Skipping merge.");
        return false;
      }

      // 2. Download cloud data
      SecurityLogger.logInfo("Sync Cycle: Downloading cloud backup...");
      // (D10) Diagnostics: Capture name and ID for better traceability on conflict
      final fileName = cloudMetadata?['name'] ?? 'unknown';
      final fileId = cloudMetadata?['id'] ?? 'unknown_id';
      final fileSize = cloudMetadata?['size'] ?? 'unknown_size';
      SecurityLogger.logInfo(
        "Sync Cycle: Found Target File [ $fileName ] (ID: $fileId, Size: $fileSize bytes)",
      );

      final cloudPayload = await _cloudSync.downloadEncryptedBackup();

      // Verification (W8): Verify the downloaded payload matches the cloud checksum
      final downloadedHash = sha256.convert(cloudPayload).toString();
      if (cloudChecksum != downloadedHash) {
        throw CloudSyncException(
          CloudSyncException.downloadFailed,
          'Integrity check failed: Cloud checksum mismatch (ID: $fileId, $cloudChecksum vs $downloadedHash)',
        );
      }

      // 3. Prepare local/cloud maps for merging
      SecurityLogger.logInfo("Sync Cycle: Preparing data for merge...");
      final localDataMap = await _dataSource.getAllDataAsMap();
      final cloudKey = await _keyProvider();
      final cloudDataMap = await _dataSource.parseCloudBackup(cloudPayload, cloudKey);

      // 4. Perform merge on background isolate using LWW
      SecurityLogger.logInfo("Sync Cycle: Entering background merge isolate...");
      final mergedDataMap = await Isolate.run(
        () => _mergeDataWorkerSer({'local': localDataMap, 'cloud': cloudDataMap}),
      );
      SecurityLogger.logInfo("Sync Cycle: background merge complete.");

      // 5. Apply merged results locally
      SecurityLogger.logInfo("Sync Cycle: Persisting merged data to local storage...");
      await _dataSource.persistMergedMap(mergedDataMap);
      SecurityLogger.logInfo("Sync Cycle: Persistence successful.");

      // 6. Final upload to ensure cloud has the merged state
      SecurityLogger.logInfo("Sync Cycle: Performing final upload of merged state...");
      await _performFullUpload();

      SecurityLogger.logInfo("Sync Cycle: SUCCESS. Local and cloud are synchronized.");
      return true;
    } catch (e, stack) {
      SecurityLogger.logError("Sync Cycle: CRITICAL FAILURE", error: e, stackTrace: stack);
      // Deep refresh: fetch metadata again on failure to catch any just-uploaded salt.
      // We must handle secondary failures here (e.g. expired token) to prevent
      // the recoveryRequired exception from being swallowed.
      try {
        final refreshedMetadata = await _cloudSync.fetchLatestCloudMetadata();
        final refreshedSalt = refreshedMetadata?['recovery_salt'];
        final localSalt = await _metadata.getRecoverySalt();

        final isIntegrityFailure = e.toString().contains("Integrity check failed");
        final anySaltExists =
            currentCloudSalt != null || refreshedSalt != null || localSalt != null;

        if (isIntegrityFailure && anySaltExists) {
          // Definitive signal: if a salt exists anywhere, decryption failure means
          // recovery passphrase is required.
          throw CloudSyncException(CloudSyncException.recoveryRequired, e);
        } else if (isIntegrityFailure && !anySaltExists) {
          // Orphan key: backup was encrypted with a random machine key that has since
          // been wiped from the Keystore. No passphrase can recover it. The user must
          // choose to overwrite with local data or reset cloud sync entirely.
          SecurityLogger.logError(
            "Sync Cycle: Orphan key detected. Cloud backup is irrecoverable without data loss.",
          );
          throw CloudSyncException(CloudSyncException.orphanKey, e);
        }
      } catch (secondaryError) {
        // Log secondary errors instead of silently discarding them.
        SecurityLogger.logError(
          "Sync Cycle: Secondary error during recovery analysis (non-fatal)",
          error: secondaryError,
        );
        // If the secondary error IS a CloudSyncException (recoveryRequired or orphanKey),
        // propagate it — it supersedes the original error.
        if (secondaryError is CloudSyncException) rethrow;
      }
      rethrow;
    }
  }

  Future<void> _performFullUpload() async {
    final cloudKey = await _keyProvider();
    final payload = await _dataSource.exportCloudBackup(cloudKey);
    final checksum = sha256.convert(payload).toString();

    // (W10) We should preserve the salt in metadata if it exists
    final localSalt = await _metadata.getRecoverySalt();

    await _cloudSync.uploadEncryptedBackup(
      payload,
      checksum,
      extraMetadata: localSalt != null ? {'recovery_salt': localSalt} : null,
    );
    await _metadata.setLastSyncChecksum(checksum);
    await _metadata.clearLocalModifiedFlag();
  }

  /// Performs a full upload of the local database to the cloud.
  /// Intended for use after key rotation.
  Future<void> forceFullUpload() async {
    await _performFullUpload();
  }
}

/// Background worker for merging data using Last-Write-Wins (LWW).
///
/// **Isolate Boundary**: This function executes on a separate background thread via `Isolate.run`.
/// This is critical because decrypting/parsing large payloads and merging hundreds of logs
/// can cause jank on the main Flutter UI thread.
///
/// **Constraint**: Because it crosses the isolate boundary, the `params` map and return value
/// must only contain primitive/serializable types (String, int, basic Lists/Maps). Complex
/// classes or connections (like database handles) cannot be passed.
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

/// Helper to merge two lists of record Maps using Last-Write-Wins (LWW) based on `updatedAt`.
///
/// **Conflict Resolution Strategy**:
/// 1. The cloud state is loaded as the baseline.
/// 2. Local records are iterated. If a local record doesn't exist in the cloud, it's added.
/// 3. If a record exists in both, their `updatedAt` timestamps are compared. The newer record wins.
/// 4. In the extremely rare case of exact millisecond ties, a deterministic tie-breaker is applied.
List<dynamic> _mergeRecordsSer({required List<dynamic> local, required List<dynamic> cloud}) {
  final Map<String, Map<String, dynamic>> merged = {};

  // Initialize with cloud records
  for (final item in cloud) {
    final record = item as Map<String, dynamic>;
    merged[record['id'] as String] = record;
  }

  // Iterate local records. If local is newer, it wins.
  for (final item in local) {
    final localRecord = item as Map<String, dynamic>;
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
        // **Deterministic Tie-Breaker**: If timestamps are perfectly identical, we must
        // ensure all devices resolve the conflict in the exact same way to avoid infinite
        // sync loops. We use the string hash of the unique UUID as the arbiter.
        if ((localRecord['id'] as String).hashCode > (cloudRecord['id'] as String).hashCode) {
          merged[id] = localRecord;
        }
      }
      // Else: Cloud record wins (already in map)
    }
  }

  return merged.values.toList();
}
