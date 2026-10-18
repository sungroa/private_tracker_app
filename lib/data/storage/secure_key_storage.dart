import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/utils/security_logger.dart';

class SecureKeyStorage {
  SecureKeyStorage(this._secureStorage);
  static const String _encryptionKeyName = 'hive_encryption_key_v1';
  static const String _cloudKeyName = 'cloud_sync_encryption_key_v1';
  static const String _supporterStatusKey = 'supporter_status_v1';

  /// Timeout for secure storage operations to prevent app hangs.
  static const Duration _storageTimeout = Duration(seconds: 3);

  final FlutterSecureStorage _secureStorage;

  /// Securely retrieves the existing encryption key or generates a new one.
  Future<List<int>> getOrCreateEncryptionKey() async {
    String? keyString;

    try {
      keyString = await _secureStorage.read(key: _encryptionKeyName).timeout(_storageTimeout);
    } catch (e, stack) {
      SecurityLogger.logError(
        "Secure storage read error for primary key",
        error: e,
        stackTrace: stack,
      );
    }

    if (keyString == null) {
      SecurityLogger.logEvent("Primary encryption key not found. Generating new key.");

      final key = Hive.generateSecureKey();
      final encoded = base64UrlEncode(key);
      try {
        await _secureStorage
            .write(key: _encryptionKeyName, value: encoded)
            .timeout(_storageTimeout);

        // Re-read to confirm the write succeeded
        keyString = await _secureStorage.read(key: _encryptionKeyName).timeout(_storageTimeout);
      } catch (e, stack) {
        SecurityLogger.logError(
          "Secure storage write/re-read error for primary key",
          error: e,
          stackTrace: stack,
        );
        if (kIsWeb) {
          throw StateError(
            'Secure storage is unavailable on this browser. '
            'Please ensure cookies and local storage are enabled and not in Incognito mode.',
          );
        }
      }

      if (keyString == null) {
        throw StateError(
          'Failed to persist encryption key to secure storage. '
          'The device keystore may be unavailable or blocked.',
        );
      }
    }

    return base64Url.decode(keyString);
  }

  /// Securely retrieves the dedicated cloud sync encryption key or generates a new one.
  Future<List<int>> getOrCreateCloudSyncKey() async {
    String? keyString;

    try {
      keyString = await _secureStorage.read(key: _cloudKeyName).timeout(_storageTimeout);
    } catch (e, stack) {
      SecurityLogger.logError(
        "Secure storage read error for cloud sync key",
        error: e,
        stackTrace: stack,
      );
    }

    if (keyString == null) {
      SecurityLogger.logEvent("Cloud sync key not found. Generating new key.");

      final key = Hive.generateSecureKey();
      final encoded = base64UrlEncode(key);
      try {
        await _secureStorage.write(key: _cloudKeyName, value: encoded).timeout(_storageTimeout);

        keyString = await _secureStorage.read(key: _cloudKeyName).timeout(_storageTimeout);
      } catch (e, stack) {
        SecurityLogger.logError(
          "Secure storage write/re-read error for cloud sync key",
          error: e,
          stackTrace: stack,
        );
      }

      if (keyString == null) {
        throw StateError(
          'Failed to persist cloud sync key to secure storage. '
          'Cloud backups will be unrecoverable if not persisted.',
        );
      }
    }

    return base64Url.decode(keyString);
  }

  /// Explicitly sets the cloud sync encryption key (used for passphrase-derived keys).
  Future<void> setCloudSyncKey(List<int> key) async {
    final encoded = base64UrlEncode(key);
    await _secureStorage.write(key: _cloudKeyName, value: encoded).timeout(_storageTimeout);
  }

  /// Deletes the cloud sync encryption key from secure storage.
  Future<void> deleteCloudSyncKey() async {
    await _secureStorage.delete(key: _cloudKeyName).timeout(_storageTimeout);
  }

  /// Securely retrieves the user's supporter status.
  Future<bool> getSupporterStatus() async {
    try {
      final value = await _secureStorage.read(key: _supporterStatusKey).timeout(_storageTimeout);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Securely persists the user's supporter status.
  Future<void> setSupporterStatus(bool isSupporter) async {
    await _secureStorage
        .write(key: _supporterStatusKey, value: isSupporter.toString())
        .timeout(_storageTimeout);
  }
}
