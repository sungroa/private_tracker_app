import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SecureKeyStorage {
  static const String _encryptionKeyName = 'hive_encryption_key_v1';
  final FlutterSecureStorage _secureStorage;

  SecureKeyStorage(this._secureStorage);

  /// Securely retrieves the existing encryption key or generates a new one.
  Future<List<int>> getOrCreateEncryptionKey() async {
    String? keyString;
    
    try {
      // On Web, secure storage can sometimes stall or timeout. 
      // We wrap it in a timeout to prevent the entire app from hanging.
      keyString = await _secureStorage.read(key: _encryptionKeyName)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint("SecureKeyStorage: Secure storage read error or timeout: $e");
      if (kIsWeb) {
        // Fallback or re-attempt logic for Web could go here.
        // For now, we allow it to proceed to generation if null.
      }
    }
    
    if (keyString == null) {
      // No key exists — generate and persist a new one
      final key = Hive.generateSecureKey();
      final encoded = base64UrlEncode(key);
      try {
        await _secureStorage.write(key: _encryptionKeyName, value: encoded)
            .timeout(const Duration(seconds: 3));
        
        // Re-read to confirm the write succeeded
        keyString = await _secureStorage.read(key: _encryptionKeyName)
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint("SecureKeyStorage: Secure storage write/re-read error: $e");
        if (kIsWeb) {
           throw StateError(
            'Secure storage is unavailable on this browser. '
            'Please ensure cookies and local storage are enabled and not in Incognito mode with blockages.'
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
}
