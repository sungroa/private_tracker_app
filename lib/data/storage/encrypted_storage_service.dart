import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/cycle_log.dart';

class EncryptedStorageService {
  static const String _encryptionKeyName = 'hive_encryption_key_v1';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Box names
  static const String cycleLogBox = 'cycle_logs';
  static const String symptomLogBox = 'symptom_logs';

  /// Initializes Hive and the encrypted boxes.
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(CycleLogAdapter());
    Hive.registerAdapter(SymptomLogAdapter());

    // Generate or fetch encryption key
    final encryptionKey = await _getOrCreateEncryptionKey();

    // Open boxes with encryption
    await Hive.openBox<CycleLog>(
      cycleLogBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    await Hive.openBox<SymptomLog>(
      symptomLogBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  /// Securely retrieves the existing encryption key or generates a new one.
  static Future<List<int>> _getOrCreateEncryptionKey() async {
    final containsKey = await _secureStorage.containsKey(key: _encryptionKeyName);
    if (!containsKey) {
      final key = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _encryptionKeyName,
        value: base64UrlEncode(key),
      );
    }
    final keyString = await _secureStorage.read(key: _encryptionKeyName);
    return base64Url.decode(keyString!);
  }

  // Generic methods for CRUD
  static Box<T> getBox<T>(String name) => Hive.box<T>(name);
}
