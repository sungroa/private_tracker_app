import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SecureKeyStorage {
  static const String _encryptionKeyName = 'hive_encryption_key_v1';
  final FlutterSecureStorage _secureStorage;

  SecureKeyStorage(this._secureStorage);

  /// Securely retrieves the existing encryption key or generates a new one.
  Future<List<int>> getOrCreateEncryptionKey() async {
    // Attempt to read existing key first
    String? keyString = await _secureStorage.read(key: _encryptionKeyName);
    
    if (keyString == null) {
      // No key exists — generate and persist a new one
      final key = Hive.generateSecureKey();
      final encoded = base64UrlEncode(key);
      await _secureStorage.write(key: _encryptionKeyName, value: encoded);
      
      // Re-read to confirm the write succeeded
      keyString = await _secureStorage.read(key: _encryptionKeyName);
      if (keyString == null) {
        throw StateError(
          'Failed to persist encryption key to secure storage. '
          'The device keystore may be unavailable.',
        );
      }
    }
    
    return base64Url.decode(keyString);
  }
}
