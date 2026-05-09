import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/usecases/sync_data_use_case.dart';
import '../../core/services/preferences_service.dart';
import '../../core/utils/security_logger.dart';
import '../../core/utils/key_derivation_util.dart';
import '../../data/storage/secure_key_storage.dart';
import '../../domain/services/cloud_sync_interface.dart';
import 'dart:convert';

/// State management provider for cloud synchronization (Google Drive / iCloud).
/// 
/// 🎨 **Presentation Architecture**: Coordinates the async sync workflow and 
/// maintains the UI state for synchronization status, errors, and last-sync 
/// timestamps.
class CloudSyncProvider with ChangeNotifier {
  final SyncDataUseCase _syncUseCase;
  final PreferencesService _prefs;
  final SecureKeyStorage _keyStorage;
  final CloudSyncInterface _cloudSync;

  bool _isSyncing = false;
  bool _isInitialized = false;
  bool _isGoogleDriveEnabled = false;
  bool _isiCloudEnabled = false;
  bool _isRecoveryEnabled = false;
  bool _isOrphanKey = false;
  String? _pendingRecoverySalt;
  String? _lastError;
  DateTime? _lastSyncTime;

  CloudSyncProvider({
    required SyncDataUseCase syncUseCase,
    required PreferencesService prefs,
    required SecureKeyStorage keyStorage,
    required CloudSyncInterface cloudSync,
  }) : _syncUseCase = syncUseCase,
       _prefs = prefs,
       _keyStorage = keyStorage,
       _cloudSync = cloudSync;

  bool get isSyncing => _isSyncing;
  bool get isInitialized => _isInitialized;
  bool get isGoogleDriveEnabled => _isGoogleDriveEnabled;
  bool get isiCloudEnabled => _isiCloudEnabled;
  bool get isCloudEnabled => (_isGoogleDriveEnabled || _isiCloudEnabled) && _isInitialized;
  bool get isRecoveryEnabled => _isRecoveryEnabled;
  /// True when the cloud backup was encrypted with a random machine key that has
  /// since been wiped from the Android Keystore. The data is irrecoverable;
  /// the user must overwrite with local data or reset cloud sync.
  bool get isOrphanKey => _isOrphanKey;
  String? get pendingRecoverySalt => _pendingRecoverySalt;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  
  bool get requiresRecoveryPrompt => isCloudEnabled && !isRecoveryEnabled && pendingRecoverySalt != null;

  /// (W2) Explicit initialization to avoid async work in constructor.
  Future<void> init() async {
    if (_isInitialized) return;
    _isGoogleDriveEnabled = await _prefs.isCloudSyncEnabled();
    _isRecoveryEnabled = await _prefs.isRecoveryPassphraseSet();
    _lastSyncTime = await _prefs.getLastSyncTime();
    
    _isInitialized = true;
    notifyListeners();

    if (_isGoogleDriveEnabled) {
      // Await recovery check so _pendingRecoverySalt is populated before any
      // subsequent sync() call can fire (fixes the AppInitializer race).
      await checkRecoveryStatus();
    }
  }

  /// Checks the cloud for an existing recovery salt.
  ///
  /// Errors are logged but not surfaced to the UI — this is a background probe.
  Future<void> checkRecoveryStatus() async {
    try {
      await _cloudSync.authenticate();
      final metadata = await _cloudSync.fetchLatestCloudMetadata();
      _pendingRecoverySalt = metadata?['recovery_salt'];
      notifyListeners();
    } catch (e) {
      // Log auth/network errors so they appear in logcat diagnostics.
      SecurityLogger.logError(
          "Cloud Sync: Background recovery check failed (non-fatal)",
          error: e);
    }
  }

  /// Sets a new recovery passphrase and re-encrypts the next backup.
  Future<void> setupRecovery(String passphrase) async {
    try {
      final salt = KeyDerivationUtil.generateSalt();
      final saltString = base64UrlEncode(salt);
      final key = KeyDerivationUtil.deriveKey(passphrase, salt);
      
      // Update local storage
      await _keyStorage.setCloudSyncKey(key);
      await _prefs.setRecoveryPassphraseSet(true);
      await _prefs.setRecoverySalt(saltString);
      
      // Also update domain-level metadata
      await _syncUseCase.setRecoverySalt(saltString);
      
      _isRecoveryEnabled = true;
      _pendingRecoverySalt = null;

      // Force a sync to upload with the new salt
      _isSyncing = true;
      notifyListeners();
      
      await _syncUseCase.execute(); 
      
      notifyListeners();
    } catch (e) {
      _lastError = "Failed to setup recovery: $e";
      notifyListeners();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Changes an existing recovery passphrase.
  ///
  /// Verifies [oldPassphrase] by attempting a real cloud backup decryption
  /// (Option A — network round-trip, most secure). Only if decryption succeeds
  /// does the key rotation proceed. This prevents unauthorized passphrase changes
  /// even if someone has physical screen access without knowing the current key.
  Future<void> changePassphrase(String oldPassphrase, String newPassphrase) async {
    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      SecurityLogger.logInfo("Cloud Sync: Verifying old passphrase via cloud decrypt...");

      // --- Step 1: Derive the old key from the stored salt ---
      final storedSaltString = await _prefs.getRecoverySalt();
      if (storedSaltString == null) {
        throw StateError('No recovery salt found locally. Cannot verify old passphrase.');
      }
      final storedSalt = base64Url.decode(storedSaltString);
      final oldKey = KeyDerivationUtil.deriveKey(oldPassphrase, storedSalt);

      // --- Step 2: Download the cloud backup and attempt decryption ---
      // This is the proof-of-knowledge check. If the old passphrase is wrong,
      // parseCloudBackup will throw an integrity/decryption exception.
      await _cloudSync.authenticate();
      final cloudPayload = await _cloudSync.downloadEncryptedBackup();
      // parseCloudBackup throws on bad key — this is intentional verification.
      await _syncUseCase.verifyCloudDecrypt(cloudPayload, oldKey);

      SecurityLogger.logInfo("Cloud Sync: Old passphrase verified. Rotating to new passphrase...");

      // --- Step 3: Key rotation — generate new salt + key, re-upload ---
      final newSalt = KeyDerivationUtil.generateSalt();
      final newSaltString = base64UrlEncode(newSalt);
      final newKey = KeyDerivationUtil.deriveKey(newPassphrase, newSalt);

      await _keyStorage.setCloudSyncKey(newKey);
      await _prefs.setRecoveryPassphraseSet(true);
      await _prefs.setRecoverySalt(newSaltString);
      await _syncUseCase.setRecoverySalt(newSaltString);

      _isRecoveryEnabled = true;

      // Force a re-upload with the new key/salt so cloud is immediately consistent.
      await _syncUseCase.execute();

      SecurityLogger.logInfo("Cloud Sync: Passphrase changed successfully.");
    } catch (e) {
      SecurityLogger.logError("Cloud Sync: Passphrase change failed", error: e);
      // Surface a user-friendly message without leaking key material.
      if (e.toString().toLowerCase().contains('integrity') ||
          e.toString().toLowerCase().contains('incorrect key') ||
          e.toString().toLowerCase().contains('bad padding') ||
          e.toString().toLowerCase().contains('decryption')) {
        _lastError = 'Old passphrase is incorrect.';
      } else {
        _lastError = 'Passphrase change failed. Please check your connection and try again.';
      }
      notifyListeners();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Restores access to cloud data using a recovery passphrase.
  Future<void> restoreRecovery(String passphrase) async {
    if (_pendingRecoverySalt == null) return;
    
    _isSyncing = true;
    notifyListeners();

    try {
      final saltBytes = base64Url.decode(_pendingRecoverySalt!);
      final key = KeyDerivationUtil.deriveKey(passphrase, saltBytes);
      
      // Update local storage
      await _keyStorage.setCloudSyncKey(key);
      await _prefs.setRecoveryPassphraseSet(true);
      _isRecoveryEnabled = true;
      _pendingRecoverySalt = null;
      
      notifyListeners();
      await sync();
    } catch (e) {
      _lastError = "Decryption failed. Please check your passphrase.";
      notifyListeners();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Resets everything in the cloud and locally.
  Future<void> resetCloudData() async {
    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      SecurityLogger.logInfo("Cloud Sync Reset: Initializing wipe operation...");
      await _cloudSync.authenticate();
      SecurityLogger.logInfo("Cloud Sync Reset: Deleting all files from appDataFolder...");
      await _cloudSync.deleteCloudData();
      
      SecurityLogger.logInfo("Cloud Sync Reset: Clearing local metadata and keys...");
      await _syncUseCase.clearLocalMetadata();
      await _keyStorage.deleteCloudSyncKey();
      
      await _prefs.setRecoveryPassphraseSet(false);
      await _prefs.setRecoverySalt(null);
      _lastSyncTime = null;
      await _prefs.setLastSyncTime(null);
      
      _isRecoveryEnabled = false;
      _pendingRecoverySalt = null;
      
      SecurityLogger.logInfo("Cloud Sync Reset: SUCCESS. Environment is now pristine.");
    } catch (e, stack) {
      SecurityLogger.logError("Cloud Sync Reset: FAILED", error: e, stackTrace: stack);
      _lastError = "Reset failed: ${e.toString()}";
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> toggleGoogleDrive(bool enabled) async {
    _isGoogleDriveEnabled = enabled;
    await _prefs.setCloudSyncEnabled(enabled);
    notifyListeners();
    
    if (enabled) {
      await checkRecoveryStatus();
      // (W12) Guard: Only sync if no recovery passphrase is pending.
      // If the cloud backup is password-protected and we don't have the key yet,
      // syncing would cause a guaranteed CRITICAL FAILURE (decryption with the
      // wrong machine-generated key). The recovery card will guide the user.
      if (!requiresRecoveryPrompt) {
        await sync();
      } else {
        SecurityLogger.logInfo("Cloud Sync: Recovery passphrase required. Deferring sync until passphrase is entered.");
      }
    }
  }

  Future<void> toggleICloud(bool enabled) async {
    _isiCloudEnabled = enabled;
    notifyListeners();
    
    if (enabled) {
      await checkRecoveryStatus();
      await sync();
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  Future<void> sync() async {
    if (!_isInitialized) await init();
    if (_isSyncing || !isCloudEnabled) return;

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      SecurityLogger.logInfo("Cloud Sync: Initiating background synchronization...");
      final changed = await _syncUseCase.execute();
      
      final now = DateTime.now();
      _lastSyncTime = now;
      await _prefs.setLastSyncTime(now);
      
      SecurityLogger.logInfo("Cloud Sync: Sync logic finished. Changes applied: $changed");
    } catch (e, stack) {
      if (e is CloudSyncException && e.message == CloudSyncException.recoveryRequired) {
        SecurityLogger.logInfo("Cloud Sync: Recovery required. Suppressing error UI for card transition.");
        _pendingRecoverySalt ??= 'pending'; // Ensure recovery card shows if salt wasn't fetched
        _lastError = null;
      } else if (e is CloudSyncException && e.message == CloudSyncException.orphanKey) {
        SecurityLogger.logError("Cloud Sync: Orphan key state. Activating recovery UI.", error: e);
        _isOrphanKey = true;
        _lastError = null; // Card UI handles this — no snackbar needed
      } else if (requiresRecoveryPrompt) {
        SecurityLogger.logInfo("Cloud Sync: App is in recovery state. Suppressing technical error.");
        _lastError = null;
      } else {
        SecurityLogger.logError("Cloud Sync: Orchestration failure", error: e, stackTrace: stack);
        _lastError = "Sync Error: ${e.toString()}";
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Overwrites the irrecoverable cloud backup with current local data.
  ///
  /// Used when the cloud backup was encrypted with a lost machine key (orphan key
  /// state). This uploads local data with a fresh random key, restoring sync.
  /// Does NOT require a passphrase — it uses the machine key path, which
  /// generates a new random key if none exists (existing local data is intact).
  Future<void> overwriteCloudWithLocal() async {
    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      SecurityLogger.logInfo("Cloud Sync: Overwriting orphan cloud backup with local data...");
      // Delete the stale backup first so the next upload is clean.
      await _cloudSync.authenticate();
      await _cloudSync.deleteCloudData();
      // Clear local metadata so execute() does a full upload (not a merge).
      await _syncUseCase.clearLocalMetadata();
      // Perform the upload — _keyProvider generates a new key if needed.
      await _syncUseCase.execute();
      _isOrphanKey = false;
      SecurityLogger.logInfo("Cloud Sync: Orphan backup overwritten. Sync restored.");
    } catch (e, stack) {
      SecurityLogger.logError("Cloud Sync: Overwrite failed", error: e, stackTrace: stack);
      _lastError = "Overwrite failed. Please check your connection and try again.";
      notifyListeners();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
