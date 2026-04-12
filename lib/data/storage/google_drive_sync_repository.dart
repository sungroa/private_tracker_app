import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../../domain/services/cloud_sync_interface.dart';

/// An authenticated HTTP client that injects GoogleSignIn auth headers into requests.
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client;

  GoogleAuthClient(this._headers, this._client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

/// Implementation of the CloudSyncInterface for Google Drive using the hidden appDataFolder.
class GoogleDriveSyncRepository implements CloudSyncInterface {
  final GoogleSignIn _googleSignIn;
  drive.DriveApi? _driveApi;
  static bool _initializedSignIn = false;

  GoogleDriveSyncRepository({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// Allows injecting a mock DriveApi for testing without needing to authenticate.
  void setMockDriveApi(drive.DriveApi api) {
    _driveApi = api;
  }

  @override
  Future<void> authenticate() async {
    try {
      if (!_initializedSignIn) {
        await _googleSignIn.initialize();
        _initializedSignIn = true;
      }

      const scope = drive.DriveApi.driveAppdataScope;
      final account = await _googleSignIn.authenticate(scopeHint: [scope]);
      
      final authHeaders = await account.authorizationClient.authorizationHeaders(
        [scope], 
        promptIfNecessary: true,
      );

      if (authHeaders == null) {
        throw CloudSyncException('Failed to obtain requested authorization headers.');
      }

      final authClient = GoogleAuthClient(authHeaders, http.Client());
      _driveApi = drive.DriveApi(authClient);
    } catch (e) {
      if (e is CloudSyncException) rethrow;
      throw CloudSyncException('Failed to authenticate with Google Drive', e);
    }
  }

  void _checkAuthenticated() {
    if (_driveApi == null) {
      throw CloudSyncException('Not authenticated. Call authenticate() first.');
    }
  }

  @override
  Future<void> uploadEncryptedBackup(File file, String checksum) async {
    _checkAuthenticated();

    try {
      final fileLength = await file.length();
      final media = drive.Media(file.openRead(), fileLength);

      final driveFile = drive.File()
        ..name = 'private_tracker_backup.enc'
        ..parents = ['appDataFolder']
        ..appProperties = {'checksum': checksum};

      // Upload the new backup
      final newFile = await _driveApi!.files.create(driveFile, uploadMedia: media);

      // Clean up old backups post-upload
      final fileList = await _driveApi!.files.list(spaces: 'appDataFolder', $fields: '*');
      final allFiles = fileList.files;
      if (allFiles != null && allFiles.isNotEmpty) {
        for (final f in allFiles) {
          if (f.id != newFile.id && f.id != null) {
            try {
              await _driveApi!.files.delete(f.id!);
            } catch (_) {
              // Ignore deletion errors to not fail the overall upload
            }
          }
        }
      }
    } catch (e) {
      throw CloudSyncException('Failed to upload backup to Google Drive', e);
    }
  }

  @override
  Future<File> downloadEncryptedBackup() async {
    _checkAuthenticated();

    try {
      final fileList = await _driveApi!.files.list(spaces: 'appDataFolder', $fields: '*');
      final allFiles = fileList.files;

      if (allFiles == null || allFiles.isEmpty) {
        throw CloudSyncException('No backup found in Google Drive');
      }

      // Sort to get the most recent one just in case cleanup failed previously
      allFiles.sort((a, b) => (b.createdTime ?? DateTime(0)).compareTo(a.createdTime ?? DateTime(0)));
      final latestBackup = allFiles.first;
      final fileId = latestBackup.id;

      if (fileId == null) throw CloudSyncException('Backup file has no ID');

      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Create a temporary file to save to
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/downloaded_backup_${DateTime.now().millisecondsSinceEpoch}.enc');

      final sink = tempFile.openWrite();
      await media.stream.pipe(sink);
      await sink.close();

      return tempFile;
    } catch (e) {
      if (e is CloudSyncException) rethrow;
      throw CloudSyncException('Failed to download backup from Google Drive', e);
    }
  }

  @override
  Future<String?> fetchLatestCloudChecksum() async {
    _checkAuthenticated();

    try {
      final fileList = await _driveApi!.files.list(spaces: 'appDataFolder', $fields: '*');
      final allFiles = fileList.files;

      if (allFiles == null || allFiles.isEmpty) {
        return null;
      }

      allFiles.sort((a, b) => (b.createdTime ?? DateTime(0)).compareTo(a.createdTime ?? DateTime(0)));
      final latestBackup = allFiles.first;

      return latestBackup.appProperties?['checksum'];
    } catch (e) {
      throw CloudSyncException('Failed to fetch latest checksum', e);
    }
  }
}
