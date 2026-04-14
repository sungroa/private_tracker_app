import '../../domain/repositories/sync_metadata_repository.dart';
import '../../core/registry/hive_registry.dart';
import '../storage/local_database_manager.dart';

/// Implementation of [ISyncMetadataRepository] for tracking synchronization state.
/// 
/// 🏛️ **Architecture**: Provides persistence for sync-related bookkeeping
/// (checksums and local modification flags). It utilizes the [HiveRegistry.metaBox] 
/// for specialized metadata storage.
class SyncMetadataRepositoryImpl implements ISyncMetadataRepository {
  final LocalDatabaseManager _dbManager;

  SyncMetadataRepositoryImpl(this._dbManager);

  @override
  Future<String?> getLastSyncChecksum() async {
    final metaBox = _dbManager.getBox<String>(HiveRegistry.metaBox);
    return metaBox.get(HiveRegistry.lastSyncChecksumKey);
  }

  @override
  Future<void> setLastSyncChecksum(String checksum) async {
    final metaBox = _dbManager.getBox<String>(HiveRegistry.metaBox);
    await metaBox.put(HiveRegistry.lastSyncChecksumKey, checksum);
  }

  @override
  Future<String?> getLastLocalModified() async {
    final metaBox = _dbManager.getBox<String>(HiveRegistry.metaBox);
    return metaBox.get(HiveRegistry.lastLocalModifiedKey);
  }

  @override
  Future<void> clearLocalModifiedFlag() async {
    final metaBox = _dbManager.getBox<String>(HiveRegistry.metaBox);
    await metaBox.delete(HiveRegistry.lastLocalModifiedKey);
  }
}
