import 'dart:io';

/// Exception thrown by CloudSyncInterface operations to handle network, auth, or quota errors gracefully.
class CloudSyncException implements Exception {
  final String message;
  final dynamic originalError;

  CloudSyncException(this.message, [this.originalError]);

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

  /// Uploads an encrypted backup file to the cloud storage.
  ///
  /// [file] The encrypted backup file to upload.
  /// [checksum] The integrity checksum of the file.
  /// Should throw [CloudSyncException] on network, quota, or other upload errors.
  Future<void> uploadEncryptedBackup(File file, String checksum);

  /// Downloads the encrypted backup from the cloud storage.
  ///
  /// Returns the downloaded [File].
  /// Should throw [CloudSyncException] on failure.
  Future<File> downloadEncryptedBackup();

  /// Fetches the latest cloud checksum to determine if a newer backup exists.
  ///
  /// Returns the checksum string, or null if no backup exists.
  /// Should throw [CloudSyncException] on failure.
  Future<String?> fetchLatestCloudChecksum();
}
