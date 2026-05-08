import 'dart:typed_data';

/// Exception thrown by CloudSyncInterface operations to handle network, auth, or quota errors gracefully.
class CloudSyncException implements Exception {
  final String message;
  final dynamic originalError;

  CloudSyncException(this.message, [this.originalError]);

  // (N2) Standardized error strings
  static const String authFailed = 'Failed to authenticate with cloud storage';
  static const String authHeadersMissing = 'Failed to obtain requested authorization headers';
  static const String notAuthenticated = 'Not authenticated. Call authenticate() first';
  static const String uploadFailed = 'Failed to upload backup to cloud storage';
  static const String downloadFailed = 'Failed to download backup from cloud storage';
  static const String fetchChecksumFailed = 'Failed to fetch latest cloud checksum';
  static const String noBackupFound = 'No backup found in cloud storage';
  static const String backupIdMissing = 'Backup file has no valid identifier';
  static const String recoveryRequired = 'Cloud backup requires a recovery passphrase';

  @override
  String toString() {
    if (originalError != null) {
      return 'CloudSyncException: $message (Original error: $originalError)';
    }
    return 'CloudSyncException: $message';
  }
}

/// Abstract interface defining the Bring Your Own Storage (BYOS) sync feature.
/// This interface must remain completely agnostic to the underlying provider (e.g., Google Drive, iCloud).
abstract class CloudSyncInterface {
  /// Authenticates the user with the cloud storage provider.
  /// Should throw [CloudSyncException] if authentication fails.
  Future<void> authenticate();

  /// Uploads an encrypted backup payload to the cloud storage.
  ///
  /// [payload] The encrypted binary data to upload.
  /// [checksum] The integrity checksum of the file.
  /// [extraMetadata] Optional key-value pairs to store with the file (e.g., encryption salt).
  /// Should throw [CloudSyncException] on network, quota, or other upload errors.
  Future<void> uploadEncryptedBackup(Uint8List payload, String checksum, {Map<String, String?>? extraMetadata});

  /// Downloads the encrypted backup from the cloud storage.
  ///
  /// Returns the raw binary payload.
  /// Should throw [CloudSyncException] on failure.
  Future<Uint8List> downloadEncryptedBackup();

  /// Fetches the latest cloud checksum to determine if a newer backup exists.
  ///
  /// Returns the checksum string, or null if no backup exists.
  /// Should throw [CloudSyncException] on failure.
  Future<String?> fetchLatestCloudChecksum();

  /// (W10) Deletes all backup data from the cloud storage.
  Future<void> deleteCloudData();

  /// Fetches the application-specific metadata (properties) associated with the latest backup.
  /// 
  /// Returns a map of properties, or null if no backup exists.
  Future<Map<String, String?>?> fetchLatestCloudMetadata();
}
