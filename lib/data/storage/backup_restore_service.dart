import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart' show compute;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;
import '../../domain/models/cycle_log.dart';
import '../../domain/models/custom_tag.dart';
import '../../domain/models/symptom_log.dart';
import 'model_mapper.dart';


class BackupRestoreService {
  static const int currentVersion = 2;
  static const int saltLength = 16;
  static const int ivLength = 16;
  static const int hmacLength = 32;

  /// Exports all data to a raw binary encrypted payload using a raw encryption key.
  Future<Uint8List> exportBackupWithKey({
    required List<int> encryptionKey,
    required List<CycleLog> cycleEvents,
    required List<SymptomLog> symptomLogs,
    required List<CustomTag> customTags,
  }) async {
    final compressedBytes = _serializeAndCompress(cycleEvents, symptomLogs, customTags);
    final iv = encrypt.IV.fromSecureRandom(ivLength);
    final rawKeyBytes = Uint8List.fromList(encryptionKey);
    
    // Derive separate keys for ENC and MAC to satisfy key separation principle
    final encKey = encrypt.Key(_calculateHmac(rawKeyBytes, utf8.encode("ENCRYPTION")));
    final hmacKey = _calculateHmac(rawKeyBytes, utf8.encode("AUTHENTICATION"));

    final encrypter = encrypt.Encrypter(encrypt.AES(encKey, mode: encrypt.AESMode.sic));
    final encrypted = encrypter.encryptBytes(compressedBytes, iv: iv);

    final dummySalt = Uint8List(saltLength); 
    final finalPayload = BytesBuilder();
    finalPayload.addByte(currentVersion);
    finalPayload.add(dummySalt);
    finalPayload.add(iv.bytes);
    
    final hmac = _calculateHmac(hmacKey, _buildHmacPayload(currentVersion, dummySalt, iv.bytes, encrypted.bytes));
    finalPayload.add(hmac);
    finalPayload.add(encrypted.bytes);

    return finalPayload.toBytes();
  }

  /// Exports all data to an encrypted and compressed (.enc) file using Authenticated Encryption and a password.
  Future<File> exportEncryptedBackup({
    required String userPassword,
    required List<CycleLog> cycleEvents,
    required List<SymptomLog> symptomLogs,
    required List<CustomTag> customTags,
  }) async {
    final compressedBytes = _serializeAndCompress(cycleEvents, symptomLogs, customTags);

    final salt = encrypt.IV.fromSecureRandom(saltLength).bytes;
    final iv = encrypt.IV.fromSecureRandom(ivLength);
    
    final keyBytes = await _deriveKeyFromPassword(userPassword, Uint8List.fromList(salt));
    final key = encrypt.Key(keyBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.sic));
    final encrypted = encrypter.encryptBytes(compressedBytes, iv: iv);

    final hmacKey = await _deriveHmacKeyFromPassword(userPassword, Uint8List.fromList(salt));
    final hmac = _calculateHmac(hmacKey, _buildHmacPayload(currentVersion, salt, iv.bytes, encrypted.bytes));

    final finalPayload = BytesBuilder();
    finalPayload.addByte(currentVersion);
    finalPayload.add(salt);
    finalPayload.add(iv.bytes);
    finalPayload.add(hmac);
    finalPayload.add(encrypted.bytes);

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/private_tracker_backup_${DateTime.now().millisecondsSinceEpoch}.enc');
    await file.writeAsBytes(finalPayload.toBytes());
    
    return file;
  }

  Uint8List _serializeAndCompress(List<CycleLog> cycleEvents, List<SymptomLog> symptomLogs, List<CustomTag> customTags) {
    final data = {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'cycleLogs': cycleEvents.map((l) => ModelMapper.cycleLogToMap(l)).toList(),
      'symptomLogs': symptomLogs.map((l) => ModelMapper.symptomLogToMap(l)).toList(),
      'customTags': customTags.map((t) => ModelMapper.customTagToMap(t)).toList(),
    };

    final jsonString = jsonEncode(data);
    final jsonBytes = utf8.encode(jsonString);
    return Uint8List.fromList(GZipEncoder().encode(jsonBytes));
  }

  /// Imports and restores data from an encrypted binary payload using a raw encryption key.
  Future<Map<String, dynamic>> importBackupWithKey(Uint8List bytes, List<int> encryptionKey) async {
    if (bytes.isEmpty) throw Exception("Invalid backup payload: empty");

    if (bytes[0] != currentVersion) throw Exception("Unsupported backup version");

    const headerSize = 1 + saltLength + ivLength + hmacLength;
    final iv = encrypt.IV(bytes.sublist(1 + saltLength, 1 + saltLength + ivLength));
    final providedHmac = bytes.sublist(1 + saltLength + ivLength, headerSize);
    final ciphertext = bytes.sublist(headerSize);

    final rawKeyBytes = Uint8List.fromList(encryptionKey);
    final hmacKey = _calculateHmac(rawKeyBytes, utf8.encode("AUTHENTICATION"));
    final encKey = encrypt.Key(_calculateHmac(rawKeyBytes, utf8.encode("ENCRYPTION")));

    final calculatedHmac = _calculateHmac(hmacKey, _buildHmacPayload(currentVersion, bytes.sublist(1, 1 + saltLength), iv.bytes, ciphertext));

    if (!_compareUint8Lists(providedHmac, calculatedHmac)) {
      throw Exception("Integrity check failed: Incorrect key or corrupted backup");
    }

    final encrypter = encrypt.Encrypter(encrypt.AES(encKey, mode: encrypt.AESMode.sic));
    final decryptedBytes = encrypter.decryptBytes(encrypt.Encrypted(ciphertext), iv: iv);

    return _decompressAndParse(decryptedBytes);
  }

  Uint8List _buildHmacPayload(int version, Uint8List salt, Uint8List iv, Uint8List ciphertext) {
    final builder = BytesBuilder();
    builder.addByte(version);
    builder.add(salt);
    builder.add(iv);
    builder.add(ciphertext);
    return builder.toBytes();
  }

  /// Imports and restores data from an encrypted backup file, supporting legacy formats.
  Future<Map<String, dynamic>> importEncryptedBackup(File file, String userPassword) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw Exception("Invalid backup file: empty");

    final firstByte = bytes[0];
    
    if (firstByte == currentVersion) {
      return await _importAuthenticatedBackup(bytes, userPassword);
    } else {
      // Assume legacy AES-CBC backup (no version byte, starts with Salt)
      return await _importLegacyBackup(bytes, userPassword);
    }
  }

  Future<Map<String, dynamic>> _importAuthenticatedBackup(Uint8List bytes, String userPassword) async {
    const headerSize = 1 + saltLength + ivLength + hmacLength;
    if (bytes.length < headerSize) throw Exception("Invalid backup file: header too small");

    // 1. Extract components
    final salt = bytes.sublist(1, 1 + saltLength);
    final iv = encrypt.IV(bytes.sublist(1 + saltLength, 1 + saltLength + ivLength));
    final providedHmac = bytes.sublist(1 + saltLength + ivLength, headerSize);
    final ciphertext = bytes.sublist(headerSize);

    // 2. Verify HMAC
    final hmacKey = await _deriveHmacKeyFromPassword(userPassword, salt);
    final calculatedHmac = _calculateHmac(hmacKey, _buildHmacPayload(currentVersion, salt, iv.bytes, ciphertext));
    
    if (!_compareUint8Lists(providedHmac, calculatedHmac)) {
      throw Exception("Integrity check failed: Incorrect password or corrupted backup");
    }

    // 3. Decrypt
    final keyBytes = await _deriveKeyFromPassword(userPassword, salt);
    final key = encrypt.Key(keyBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.sic));
    final decryptedBytes = encrypter.decryptBytes(encrypt.Encrypted(ciphertext), iv: iv);

    return _decompressAndParse(decryptedBytes);
  }

  Future<Map<String, dynamic>> _importLegacyBackup(Uint8List bytes, String userPassword) async {
    if (bytes.length < 32) throw Exception("Invalid legacy backup: too small");

    // Extract Salt, IV, and Ciphertext (Legacy: [Salt(16)] [IV(16)] [Ciphertext])
    final salt = bytes.sublist(0, 16);
    final iv = encrypt.IV(bytes.sublist(16, 32));
    final ciphertext = bytes.sublist(32);

    final keyBytes = await _deriveKeyFromPassword(userPassword, salt);
    final key = encrypt.Key(keyBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    
    try {
      final decryptedBytes = encrypter.decryptBytes(encrypt.Encrypted(ciphertext), iv: iv);
      return _decompressAndParse(decryptedBytes);
    } catch (e) {
      throw Exception("Legacy decryption failed: Incorrect password or corrupted file");
    }
  }

  Map<String, dynamic> _decompressAndParse(List<int> decryptedBytes) {
    final decompressedBytes = GZipDecoder().decodeBytes(decryptedBytes);
    final jsonString = utf8.decode(decompressedBytes);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  Future<Uint8List> _deriveKeyFromPassword(String password, Uint8List salt) async {
    return compute(_deriveKeyWorker, {
      'password': password,
      'salt': salt,
    });
  }

  Future<Uint8List> _deriveHmacKeyFromPassword(String password, Uint8List salt) async {
    return compute(_deriveHmacKeyWorker, {
      'password': password,
      'salt': salt,
    });
  }

  Uint8List _calculateHmac(Uint8List key, Uint8List data) {
    final hmac = pc.HMac(pc.SHA256Digest(), 64);
    hmac.init(pc.KeyParameter(key));
    return hmac.process(data);
  }

  bool _compareUint8Lists(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    // Constant-time comparison to prevent timing attacks
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

/// (W10) Background workers for key derivation to avoid blocking main isolate
Uint8List _deriveKeyWorker(Map<String, dynamic> params) {
  final String password = params['password'] as String;
  final Uint8List salt = params['salt'] as Uint8List;
  
  final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64));
  pbkdf2.init(pc.Pbkdf2Parameters(salt, 10000, 32));
  return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
}

Uint8List _deriveHmacKeyWorker(Map<String, dynamic> params) {
  final String password = params['password'] as String;
  final Uint8List salt = params['salt'] as Uint8List;
  
  final hmacSalt = Uint8List.fromList(salt + utf8.encode("HMAC_AUTH"));
  final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64));
  pbkdf2.init(pc.Pbkdf2Parameters(hmacSalt, 10000, 32));
  return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
}
