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
///
/// 🔄 **State Machine**:
/// This provider implements a finite state machine to manage the complex lifecycle
/// of encrypted cloud backups:
/// - **Disabled**: Cloud sync is off. No network calls are made.
/// - **Syncing**: An active upload/download/merge operation is running in the background.
/// - **Recovery Required**: A cloud backup exists and is protected by a passphrase, but 
///   the local device does not have the key. All sync operations are blocked until the user 
///   provides the passphrase to derive the key.
/// - **Orphan Key**: The cloud backup was encrypted using a machine-generated key that 
///   has since been lost (e.g., due to an OS-level Keystore wipe). The backup is permanently 
///   irrecoverable and must be overwritten.
class CloudSyncProvider with ChangeNotifier {
  final SyncDataUseCase _syncUseCase;
  final PreferencesService _prefs;
  final SecureKeyStorage _keyStorage;
  final CloudSyncInterface _cloudSync;

  bool _isSyncing = false;
  bool _isInitialized = false;
  bool _isGoogleDriveEnabled = false;
  bool _isiCloudEnabled = false;
  /// UI State: True if the user has successfully entered their recovery passphrase
  /// and the key is available locally. If false while [isCloudEnabled] is true, 
  /// the app may need to prompt for recovery.
  bool _isRecoveryEnabled = false;
  
  bool _isOrphanKey = false;

  /// True if the cloud storage contains at least one backup file.
  /// Populated by [checkRecoveryStatus] to distinguish first-time setup
  /// from migration scenarios.
  bool _cloudBackupExists = false;

  /// True when [checkRecoveryStatus] failed (e.g. auth error). When set,
  /// sync is suppressed until a successful recovery check clears this.
  bool _recoveryCheckFailed = false;
  
  /// Cryptographic State: The salt found in the cloud backup's metadata.
  /// If this is non-null AND [_isRecoveryEnabled] is false, it means we have 
  /// discovered a password-protected backup but haven't unlocked it yet.
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
  bool get cloudBackupExists => _cloudBackupExists;
  String? get pendingRecoverySalt => _pendingRecoverySalt;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  
  bool get requiresRecoveryPrompt => isCloudEnabled && !isRecoveryEnabled && pendingRecoverySalt != null;

  /// True when cloud sync is enabled but no backup exists yet and no passphrase
  /// has been configured. The user must set a passphrase before the first upload.
  bool get needsInitialSetup =>
      isCloudEnabled && !_isRecoveryEnabled && !_cloudBackupExists &&
      _pendingRecoverySalt == null && !_isOrphanKey;

  /// True when cloud sync is enabled and an existing backup was encrypted with
  /// a machine-generated key (no recovery salt). The user must set a passphrase
  /// so their backup becomes recoverable on new devices.
  bool get needsPassphraseMigration =>
      isCloudEnabled && !_isRecoveryEnabled && _cloudBackupExists &&
      _pendingRecoverySalt == null && !_isOrphanKey;

  /// True when any form of setup is required before sync can proceed.
  bool get needsAnySetup =>
      requiresRecoveryPrompt || needsInitialSetup || needsPassphraseMigration || _isOrphanKey || _recoveryCheckFailed;

  /// Initializes the provider's state from local storage and optionally probes the cloud.
  ///
  /// **Race Condition Prevention**: This method is called by `AppInitializer` during app startup.
  /// By `await`ing `checkRecoveryStatus()`, we guarantee that the `_pendingRecoverySalt` is
  /// populated *before* the UI renders or any automatic `sync()` calls fire. This prevents
  /// the app from trying to download and decrypt a password-protected backup with a standard
  /// machine key, which would result in a fatal `BadPaddingException`.
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
      SecurityLogger.logInfo(
        'Cloud Sync: Init complete. '
        'isCloudEnabled=$isCloudEnabled, '
        'isRecoveryEnabled=$_isRecoveryEnabled, '
        'pendingRecoverySalt=${_pendingRecoverySalt != null ? "<set>" : "null"}, '
        'requiresRecoveryPrompt=$requiresRecoveryPrompt, '
        'isOrphanKey=$_isOrphanKey');
    }
  }

  /// Checks the cloud for an existing recovery salt and backup presence.
  ///
  /// Populates [_cloudBackupExists] and [_pendingRecoverySalt] so the UI can
  /// determine which setup flow to show. Returns `true` on success.
  /// On failure (auth/network error), sets [_recoveryCheckFailed] to suppress
  /// sync until the next successful check.
  Future<bool> checkRecoveryStatus() async {
    try {
      await _cloudSync.authenticate();
      final metadata = await _cloudSync.fetchLatestCloudMetadata();
      _cloudBackupExists = metadata != null;
      _pendingRecoverySalt = metadata?['recovery_salt'];
      _recoveryCheckFailed = false;
      if (_pendingRecoverySalt != null) {
        SecurityLogger.logInfo(
            "Cloud Sync: Recovery salt detected in cloud backup. Recovery card will be shown.");
      } else if (_cloudBackupExists) {
        SecurityLogger.logInfo(
            "Cloud Sync: Backup exists but has no recovery salt (machine-key encrypted). Migration required.");
      } else {
        SecurityLogger.logInfo(
            "Cloud Sync: No cloud backup found. Initial setup required.");
      }
      notifyListeners();
      return true;
    } catch (e) {
      _recoveryCheckFailed = true;
      _lastError = "Cloud authentication failed. Please try again.";
      SecurityLogger.logError(
          "Cloud Sync: Recovery check failed — sync suppressed until next successful check",
          error: e);
      notifyListeners();
      return false;
    }
  }

  /// Sets a new recovery passphrase and uploads an encrypted backup.
  ///
  /// Used for first-time setup when no cloud backup exists yet.
  /// Uses [forceFullUpload] instead of [execute] to avoid a redundant
  /// [authenticate] call that races with the Credential Manager UI
  /// right after the passphrase dialog dismisses.
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

      // Upload with the new passphrase-derived key. We use forceFullUpload()
      // (not execute()) because: (1) there's no cloud backup to download/merge
      // for initial setup, and (2) execute() calls authenticate() which
      // re-triggers the Credential Manager and gets auto-cancelled when
      // invoked immediately after a dialog dismissal.
      _isSyncing = true;
      notifyListeners();
      
      await _syncUseCase.forceFullUpload(); 
      
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

      SecurityLogger.logInfo("Cloud Sync: Old passphrase verified. Syncing before key rotation...");

      // --- Step 2.5: Ensure we are fully synced before rotating ---
      // We must merge any pending cloud changes first so we don't overwrite them.
      await _syncUseCase.execute();

      SecurityLogger.logInfo("Cloud Sync: Rotating to new passphrase...");

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
      await _syncUseCase.forceFullUpload();

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
    // Resolve the real salt: use _pendingRecoverySalt if it's a genuine base64
    // value. If it's the 'pending' sentinel (Drive metadata had no salt), fall
    // back to the locally stored prefs salt — the one the SyncDataUseCase used
    // to determine that recovery is required.
    String? saltToUse = _pendingRecoverySalt;
    if (saltToUse == null || saltToUse == 'pending') {
      saltToUse = await _prefs.getRecoverySalt();
    }
    if (saltToUse == null) return;
    
    _isSyncing = true;
    notifyListeners();

    try {
      final saltBytes = base64Url.decode(saltToUse);
      final key = KeyDerivationUtil.deriveKey(passphrase, saltBytes);
      
      // Update local storage
      await _keyStorage.setCloudSyncKey(key);
      await _prefs.setRecoveryPassphraseSet(true);
      await _prefs.setRecoverySalt(saltToUse);
      await _syncUseCase.setRecoverySalt(saltToUse);
      
      _isRecoveryEnabled = true;
      _pendingRecoverySalt = null;
      
      notifyListeners();
      await sync();
      
      // If sync() failed and suppressed the exception by reverting to recovery mode,
      // the passphrase must have been incorrect.
      if (!_isRecoveryEnabled || _pendingRecoverySalt != null) {
        throw Exception("Incorrect passphrase");
      }
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
      final checkOk = await checkRecoveryStatus();
      // (W12) Guard: Only sync if recovery check succeeded AND no setup pending.
      if (checkOk && !needsAnySetup) {
        await sync();
      } else {
        SecurityLogger.logInfo(
          "Cloud Sync: Setup required before sync. "
          "checkOk=$checkOk, initialSetup=$needsInitialSetup, "
          "migration=$needsPassphraseMigration, "
          "recovery=$requiresRecoveryPrompt, orphan=$_isOrphanKey");
      }
    } else {
      // (W13) Force a clean sign-out when disabling so the next attempt starts fresh.
      _cloudBackupExists = false;
      await _cloudSync.signOut();
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
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  Future<void> sync() async {
    if (!_isInitialized) await init();
    if (_isSyncing || !isCloudEnabled) return;

    // (W14) Setup guard: refuse to sync when any form of passphrase setup,
    // migration, or recovery is required. Attempting sync in these states
    // guarantees a CRITICAL FAILURE (wrong or missing decryption key).
    if (needsAnySetup) {
      SecurityLogger.logInfo(
          "Cloud Sync: Sync suppressed — setup/migration/recovery is required first.");
      return;
    }

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
        // (W15) The locally stored key is PROVABLY wrong — decryption failed.
        // Force _isRecoveryEnabled=false so requiresRecoveryPrompt can become
        // true and the orange recovery card appears in Settings.
        _isRecoveryEnabled = false;
        await _prefs.setRecoveryPassphraseSet(false);
        
        // Fetch the latest salt from cloud so the recovery prompt uses the correct salt
        // for key derivation (especially critical if passphrase was rotated on another device).
        await checkRecoveryStatus();
        
        if (_pendingRecoverySalt == null) {
          _pendingRecoverySalt = await _prefs.getRecoverySalt() ?? 'pending';
          SecurityLogger.logInfo(
              "Cloud Sync: Using local prefs salt as fallback. "
              "pendingRecoverySalt=${_pendingRecoverySalt != null ? '<set>' : 'null'}");
        }
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

  /// Migrates from a machine-generated encryption key to a user-chosen passphrase.
  ///
  /// Unlike [setupRecovery] (which sets the key first then uploads), this method
  /// must sync with the **existing** machine key first — the cloud backup is
  /// encrypted with that key, so decrypting with a new passphrase-derived key
  /// would cause an integrity failure.
  ///
  /// Flow: sync (old key) → rotate key → force re-upload (new key).
  Future<void> migrateToPassphrase(String passphrase) async {
    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      SecurityLogger.logInfo("Cloud Sync: Starting machine-key → passphrase migration...");

      // Step 1: Ensure fully synced with current machine key
      await _syncUseCase.execute();
      SecurityLogger.logInfo("Cloud Sync: Pre-migration sync complete.");

      // Step 2: Derive new key from passphrase
      final salt = KeyDerivationUtil.generateSalt();
      final saltString = base64UrlEncode(salt);
      final key = KeyDerivationUtil.deriveKey(passphrase, salt);

      // Step 3: Rotate key in local storage
      await _keyStorage.setCloudSyncKey(key);
      await _prefs.setRecoveryPassphraseSet(true);
      await _prefs.setRecoverySalt(saltString);
      await _syncUseCase.setRecoverySalt(saltString);

      _isRecoveryEnabled = true;

      // Step 4: Re-upload with new key (no download/merge — data is already current)
      await _syncUseCase.forceFullUpload();

      SecurityLogger.logInfo("Cloud Sync: Migration complete. Backup is now passphrase-protected.");
    } catch (e, stack) {
      SecurityLogger.logError("Cloud Sync: Migration failed", error: e, stackTrace: stack);
      _lastError = "Migration failed. Please check your connection and try again.";
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Reverts cloud sync toggle when the user cancels a required setup dialog.
  Future<void> cancelCloudSetup() async {
    _isGoogleDriveEnabled = false;
    _cloudBackupExists = false;
    _pendingRecoverySalt = null;
    await _prefs.setCloudSyncEnabled(false);
    await _cloudSync.signOut();
    notifyListeners();
  }
}
