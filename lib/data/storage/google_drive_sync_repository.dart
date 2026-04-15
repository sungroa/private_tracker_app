import 'dart:typed_data';

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

  @override
  void close() {
    _client.close();
    super.close();
  }
}

/// Implementation of the CloudSyncInterface for Google Drive using the hidden appDataFolder.
class GoogleDriveSyncRepository implements CloudSyncInterface {
  final GoogleSignIn _googleSignIn;
  drive.DriveApi? _driveApi;
  http.Client? _authClient;
  final String? _serverClientId;
  bool _initializedSignIn = false;

  GoogleDriveSyncRepository({
    GoogleSignIn? googleSignIn,
    String? serverClientId,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _serverClientId = serverClientId;

  /// Allows injecting a mock DriveApi for testing without needing to authenticate.
  void setMockDriveApi(drive.DriveApi api) {
    _driveApi = api;
  }

  @override
  Future<void> authenticate() async {
    try {
      if (!_initializedSignIn) {
        // (W10) Client configuration required on Android for this plugin version
        await _googleSignIn.initialize(serverClientId: _serverClientId);
        _initializedSignIn = true;
      }

      const scope = drive.DriveApi.driveAppdataScope;
      
      // (W10) Attempt silent sign-in first to avoid account picker
      GoogleSignInAccount? account = await _googleSignIn.attemptLightweightAuthentication();
      account ??= await _googleSignIn.authenticate(scopeHint: [scope]);

      final authHeaders = await account.authorizationClient.authorizationHeaders(
        [scope], 
        promptIfNecessary: true,
      );
      if (authHeaders == null) {
        throw CloudSyncException(CloudSyncException.authHeadersMissing);
      }

      // Fix C7: Use a dedicated client that we can close
      _authClient?.close();
      final authClient = GoogleAuthClient(authHeaders, http.Client());
      _authClient = authClient;
      _driveApi = drive.DriveApi(authClient);
    } catch (e) {
      if (e is CloudSyncException) rethrow;
      throw CloudSyncException(CloudSyncException.authFailed, e);
    }
  }

  void _checkAuthenticated() {
    if (_driveApi == null) {
      throw CloudSyncException(CloudSyncException.notAuthenticated);
    }
  }

  @override
  Future<void> uploadEncryptedBackup(Uint8List payload, String checksum) async {
    _checkAuthenticated();

    try {
      final media = drive.Media(Stream.value(payload), payload.length);

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
      throw CloudSyncException(CloudSyncException.uploadFailed, e);
    }
  }

  @override
  Future<Uint8List> downloadEncryptedBackup() async {
    _checkAuthenticated();

    try {
      final fileList = await _driveApi!.files.list(spaces: 'appDataFolder', $fields: '*');
      final allFiles = fileList.files;

      if (allFiles == null || allFiles.isEmpty) {
        throw CloudSyncException(CloudSyncException.noBackupFound);
      }

      // Sort to get the most recent one just in case cleanup failed previously
      allFiles.sort((a, b) => (b.createdTime ?? DateTime(0)).compareTo(a.createdTime ?? DateTime(0)));
      final latestBackup = allFiles.first;
      final fileId = latestBackup.id;

      if (fileId == null) throw CloudSyncException(CloudSyncException.backupIdMissing);

      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Drain the stream into a ByteBuilder to avoid temp files (W1 compliance)
      final builder = BytesBuilder(copy: false);
      await for (final chunk in media.stream) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } catch (e) {
      if (e is CloudSyncException) rethrow;
      throw CloudSyncException(CloudSyncException.downloadFailed, e);
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
      throw CloudSyncException(CloudSyncException.fetchChecksumFailed, e);
    }
  }

  /// Properly closes authenticated clients to prevent memory leaks and dangling sockets.
  void dispose() {
    _authClient?.close();
    _authClient = null;
    _driveApi = null;
  }
}
