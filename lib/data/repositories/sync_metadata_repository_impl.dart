import '../../domain/repositories/sync_metadata_repository.dart';
import '../storage/local_database_manager.dart';

class SyncMetadataRepositoryImpl implements ISyncMetadataRepository {
  final LocalDatabaseManager _dbManager;

  SyncMetadataRepositoryImpl(this._dbManager);

  @override
  Future<String?> getLastSyncChecksum() async {
    final metaBox = _dbManager.getBox<String>(LocalDatabaseManager.metaBox);
    return metaBox.get(LocalDatabaseManager.lastSyncChecksumKey);
  }

  @override
  Future<void> setLastSyncChecksum(String checksum) async {
    final metaBox = _dbManager.getBox<String>(LocalDatabaseManager.metaBox);
    await metaBox.put(LocalDatabaseManager.lastSyncChecksumKey, checksum);
  }

  @override
  Future<String?> getLastLocalModified() async {
    final metaBox = _dbManager.getBox<String>(LocalDatabaseManager.metaBox);
    return metaBox.get(LocalDatabaseManager.lastLocalModifiedKey);
  }

  @override
  Future<void> clearLocalModifiedFlag() async {
    final metaBox = _dbManager.getBox<String>(LocalDatabaseManager.metaBox);
    await metaBox.delete(LocalDatabaseManager.lastLocalModifiedKey);
  }
}
