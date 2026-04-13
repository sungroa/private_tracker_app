/// Domain interface for managing synchronization-related metadata.
/// 
/// This repository decouples the domain layer from Hive-specific implementation
/// details like the 'meta' box and its keys.
abstract class ISyncMetadataRepository {
  /// Retrieves the checksum of the last successful cloud-to-local synchronization.
  Future<String?> getLastSyncChecksum();

  /// Updates the checksum of the last successful synchronization.
  Future<void> setLastSyncChecksum(String checksum);

  /// Retrieves the timestamp (ISO8601) of the last local modification.
  /// 
  /// Returns null if the local state has not been modified since the last sync.
  Future<String?> getLastLocalModified();

  /// Resets the local modification flag.
  /// 
  /// Typically called after a successful upload to indicate local state is in sync with cloud.
  Future<void> clearLocalModifiedFlag();
}
