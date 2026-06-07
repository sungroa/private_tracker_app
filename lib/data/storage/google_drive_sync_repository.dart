import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../../domain/services/cloud_sync_interface.dart';
import '../../core/utils/security_logger.dart';

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

  /// Cached account from the last successful authentication. Reusing the same
  /// [GoogleSignInAccount] instance lets its [authorizationClient] reuse a
  /// warm token cache, avoiding repeated Credential Manager UI invocations.
  GoogleSignInAccount? _cachedAccount;

  String get _backupFileName =>
      kDebugMode ? 'private_tracker_backup_dev.enc' : 'private_tracker_backup.enc';

  GoogleDriveSyncRepository({
    GoogleSignIn? googleSignIn,
    // serverClientId is retained for API compatibility but initialize() is now
    // called at app startup (main.dart), so it is no longer used here.
    String? serverClientId,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// Allows injecting a mock DriveApi for testing without needing to authenticate.
  void setMockDriveApi(drive.DriveApi api) {
    _driveApi = api;
  }

  /// Clears the cached account, forcing a full re-authentication on the next call.
  /// Should be called on sign-out or when the account is known to be invalid.
  void clearCachedAccount() {
    _cachedAccount = null;
  }

  @override
  Future<void> authenticate() async {
    // Smart session refresh strategy:
    //   1. If we have a cached account, try to get auth headers silently from it.
    //      The authorizationClient holds a refresh token that works offline.
    //   2. If that fails (null headers = truly expired), fall back to a fresh
    //      attemptLightweightAuthentication() — still silent, no Credential Manager UI.
    //   3. If the lightweight attempt also fails (account removed), then
    //      fall back to a full interactive authenticate() call.
    //   NEVER use promptIfNecessary: true — that is what triggers the sign-in sheet.
    try {
      SecurityLogger.logInfo("Google Drive: Refreshing authentication session...");

      const scope = drive.DriveApi.driveAppdataScope;
      Map<String, String>? authHeaders;

      // --- Step 1: Try the cached account first (no network roundtrip). ---
      if (_cachedAccount != null) {
        SecurityLogger.logInfo("Google Drive: Reusing cached account for silent token refresh...");
        authHeaders = await _cachedAccount!.authorizationClient
            .authorizationHeaders([scope], promptIfNecessary: false);
        if (authHeaders == null) {
          SecurityLogger.logInfo("Google Drive: Cached token expired or insufficient. Fetching fresh account...");
          _cachedAccount = null; // invalidate stale cache
        }
      }

      // --- Step 2: Fetch a fresh account silently if needed. ---
      if (authHeaders == null) {
        SecurityLogger.logInfo("Google Drive: Attempting lightweight sign-in...");
        GoogleSignInAccount? account;
        try {
          account = await _googleSignIn.attemptLightweightAuthentication();
        } catch (e) {
          SecurityLogger.logInfo("Google Drive: Lightweight auth threw exception ($e). Falling back to interactive auth.");
          account = null;
        }

        if (account == null) {
          // Only reached if the user has never signed in, revoked access, or 
          // their session needs re-authentication.
          SecurityLogger.logInfo(
              "Google Drive: Lightweight auth failed. Requesting user sign-in...");
          account = await _googleSignIn.authenticate();
        }

        SecurityLogger.logInfo(
            "Google Drive: Account obtained. Fetching authorization headers...");

        // Attempt to fetch headers with the requested scope.
        authHeaders = await account.authorizationClient
            .authorizationHeaders([scope], promptIfNecessary: false);

        if (authHeaders == null) {
          // (W12) Fallback: If headers are missing despite an account, it likely means 
          // the scope wasn't granted yet. Retry with a full authorization prompt.
          SecurityLogger.logInfo("Google Drive: Silent headers failed. Retrying with full authorization...");
          final auth = await account.authorizationClient.authorizeScopes([scope]);
          // Construct headers manually as authorizationHeaders is not defined on GoogleSignInClientAuthorization
          authHeaders = {
            'Authorization': 'Bearer ${auth.accessToken}',
          };
        }


        // Cache the account so future calls skip Steps 1+2 entirely.
        _cachedAccount = account;
      }

      _setupDriveApi(authHeaders);
      SecurityLogger.logInfo("Google Drive: Drive API client ready.");
    } catch (e) {
      SecurityLogger.logError("Google Drive: Authentication failed", error: e);
      if (e is CloudSyncException) rethrow;
      throw CloudSyncException(CloudSyncException.authFailed, e);
    }
  }

  void _setupDriveApi(Map<String, String> headers) {
    _authClient?.close();
    final authClient = GoogleAuthClient(headers, http.Client());
    _authClient = authClient;
    _driveApi = drive.DriveApi(authClient);
  }

  void _checkAuthenticated() {
    if (_driveApi == null) {
      throw CloudSyncException(CloudSyncException.notAuthenticated);
    }
  }

  @override
  Future<void> uploadEncryptedBackup(Uint8List payload, String checksum,
      {Map<String, String?>? extraMetadata}) async {
    _checkAuthenticated();

    try {
      final media = drive.Media(Stream.value(payload), payload.length);

      // Build the primary metadata map (appProperties supports nullable values).
      final appPropertiesMap = <String, String?>{
        'checksum': checksum,
        if (extraMetadata != null) ...extraMetadata,
      };

      // Triple-redundant metadata storage so the recovery salt survives
      // across Drive API scope differences and device transitions:
      //   • appProperties — app-private; may be masked on some Drive API scopes.
      //   • properties    — public fallback; visible across Drive API scopes.
      //   • description   — last-resort plain-text fallback, prefixed 'salt:'.
      final propertiesMap = Map.fromEntries(
        appPropertiesMap.entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
      final recoverySalt = extraMetadata?['recovery_salt'];

      final driveFile = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder']
        ..appProperties = appPropertiesMap
        ..properties = propertiesMap
        ..description = recoverySalt != null ? 'salt:$recoverySalt' : null;

      // Upload the new backup
      final newFile =
          await _driveApi!.files.create(driveFile, uploadMedia: media);
      SecurityLogger.logInfo("Upload successful. File ID: ${newFile.id}");

      // Clean up old backups post-upload
      SecurityLogger.logInfo("Cleaning up old backups...");
      final fileList = await _driveApi!.files.list(
        q: "name = '$_backupFileName'",
        spaces: 'appDataFolder',
        $fields: '*',
      );
      final allFiles = fileList.files;
      if (allFiles != null && allFiles.isNotEmpty) {
        for (final f in allFiles) {
          if (f.id != newFile.id && f.id != null) {
            try {
              await _driveApi!.files.delete(f.id!);
            } catch (_) {
              // Ignore individual deletion errors to not fail the overall upload
            }
          }
        }
      }
    } catch (e) {
      SecurityLogger.logError("Upload failed", error: e);
      throw CloudSyncException(CloudSyncException.uploadFailed, e);
    }
  }

  @override
  Future<Uint8List> downloadEncryptedBackup() async {
    _checkAuthenticated();

    try {
      SecurityLogger.logInfo("Listing cloud backups for download...");
      final fileList = await _driveApi!.files.list(
        q: "name = '$_backupFileName'",
        spaces: 'appDataFolder',
        $fields: '*',
      );
      final allFiles = fileList.files;

      if (allFiles == null || allFiles.isEmpty) {
        throw CloudSyncException(CloudSyncException.noBackupFound);
      }

      // Sort to get the most recent one just in case cleanup failed previously
      allFiles.sort((a, b) => (b.createdTime ?? DateTime(0)).compareTo(a.createdTime ?? DateTime(0)));
      final latestBackup = allFiles.first;
      final fileId = latestBackup.id;

      if (fileId == null) throw CloudSyncException(CloudSyncException.backupIdMissing);

      SecurityLogger.logInfo("Found ${allFiles.length} files. Downloading latest (ID: $fileId)...");
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Drain the stream into a ByteBuilder to avoid temp files (W1 compliance)
      final builder = BytesBuilder(copy: false);
      await for (final chunk in media.stream) {
        builder.add(chunk);
      }
      SecurityLogger.logInfo("Download complete (${builder.length} bytes).");
      return builder.takeBytes();
    } catch (e) {
      SecurityLogger.logError("Download failed", error: e);
      if (e is CloudSyncException) rethrow;
      throw CloudSyncException(CloudSyncException.downloadFailed, e);
    }
  }

  @override
  Future<void> deleteCloudData() async {
    _checkAuthenticated();
    try {
      SecurityLogger.logInfo("Cloud Wipe: Initializing exhaustive search in appDataFolder...");
      
      int deletedCount = 0;
      String? pageToken;
      
      do {
        final fileList = await _driveApi!.files.list(
          q: "name = '$_backupFileName'",
          spaces: 'appDataFolder',
          $fields: 'nextPageToken, files(id, name, createdTime, size)',
          pageToken: pageToken,
          pageSize: 100,
        );

        final files = fileList.files;
        if (files == null || files.isEmpty) {
          if (deletedCount == 0) {
            SecurityLogger.logInfo("Cloud Wipe: No files found in appDataFolder.");
          }
          break;
        }

        SecurityLogger.logInfo("Cloud Wipe: Found ${files.length} files on current page. Deleting...");
        for (final f in files) {
          if (f.id != null) {
            SecurityLogger.logInfo("Cloud Wipe: Deleting [${f.name}] (ID: ${f.id}, Size: ${f.size}, Created: ${f.createdTime})");
            await _driveApi!.files.delete(f.id!);
            deletedCount++;
          }
        }
        
        pageToken = fileList.nextPageToken;
      } while (pageToken != null);

      SecurityLogger.logInfo("Cloud Wipe: COMPLETE. Total files deleted: $deletedCount");
    } catch (e) {
      SecurityLogger.logError("Cloud Wipe: FAILED to purge appDataFolder", error: e);
      throw CloudSyncException("Failed to delete cloud data.", e);
    }
  }

  @override
  Future<String?> fetchLatestCloudChecksum() async {
    final metadata = await fetchLatestCloudMetadata();
    return metadata?['checksum'];
  }

  @override
  Future<Map<String, String?>?> fetchLatestCloudMetadata() async {
    _checkAuthenticated();

    try {
      final fileList = await _driveApi!.files.list(
        q: "name = '$_backupFileName'",
        spaces: 'appDataFolder',
        $fields: '*',
      );
      final allFiles = fileList.files;

      if (allFiles == null || allFiles.isEmpty) {
        return null;
      }

      allFiles.sort((a, b) => (b.createdTime ?? DateTime(0)).compareTo(a.createdTime ?? DateTime(0)));
      final latestBackup = allFiles.first;

      // (C3) Robust retrieval: check appProperties, then properties, then description
      final Map<String, String?> metadata = {
        'id': latestBackup.id,
        'name': latestBackup.name,
        'size': latestBackup.size,
      };
      
      // 1. Initial maps
      if (latestBackup.appProperties != null) metadata.addAll(latestBackup.appProperties!);
      if (latestBackup.properties != null) metadata.addAll(latestBackup.properties!);
      
      // 2. Description fallback for salt
      if (metadata['recovery_salt'] == null && latestBackup.description != null) {
        final desc = latestBackup.description!;
        if (desc.startsWith('salt:')) {
          metadata['recovery_salt'] = desc.substring(5);
        }
      }

      return metadata;
    } catch (e) {
      throw CloudSyncException(CloudSyncException.fetchChecksumFailed, e);
    }
  }

  /// Properly closes authenticated clients to prevent memory leaks and dangling sockets.
  void dispose() {
    _authClient?.close();
    _authClient = null;
    _driveApi = null;
    _cachedAccount = null;
  }

  @override
  Future<void> signOut() async {
    try {
      SecurityLogger.logInfo("Google Drive: Signing out and clearing tokens...");
      clearCachedAccount();
      // Disconnect fully revokes access, which helps reset Android 14 Credential Manager
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
      dispose();
    } catch (e) {
      SecurityLogger.logError("Google Drive: Sign out failed", error: e);
    }
  }
}
