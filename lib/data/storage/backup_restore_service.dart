import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;
import '../../domain/models/cycle_log.dart';
import '../../domain/models/custom_tag.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';


class BackupRestoreService {
  static const int currentVersion = 2;
  static const int saltLength = 16;
  static const int ivLength = 16;
  static const int hmacLength = 32;

  /// Exports all data to an encrypted and compressed (.enc) file using Authenticated Encryption.
  Future<File> exportEncryptedBackup({
    required String userPassword,
    required List<CycleEvent> cycleEvents,
    required List<SymptomLog> symptomLogs,
    required List<CustomTag> customTags,
  }) async {
    // 1. Serialize all data
    final data = {
      'version': 1, // Logic version of data schema
      'createdAt': DateTime.now().toIso8601String(),
      'cycleLogs': cycleEvents.map((l) => l.toMap()).toList(),
      'symptomLogs': symptomLogs.map((l) => l.toMap()).toList(),
      'customTags': customTags.map((t) => t.toMap()).toList(),
    };

    final jsonString = jsonEncode(data);

    // 2. Compress (GZip) - GZip output can be null if it fails
    final jsonBytes = utf8.encode(jsonString);
    final compressedBytes = GZipEncoder().encode(jsonBytes);
    if (compressedBytes == null) throw Exception("Compression failed");

    // 3. Encrypt (AES-256-SIC / CTR)
    final salt = encrypt.IV.fromSecureRandom(saltLength).bytes;
    final iv = encrypt.IV.fromSecureRandom(ivLength);
    
    final keyBytes = await _deriveKeyFromPassword(userPassword, Uint8List.fromList(salt));
    final key = encrypt.Key(keyBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.sic));
    
    final encrypted = encrypter.encryptBytes(compressedBytes, iv: iv);

    // 4. Calculate HMAC-SHA256 over [Version] [Salt] [IV] [Ciphertext]
    final hmacKey = await _deriveHmacKeyFromPassword(userPassword, Uint8List.fromList(salt));
    final hmacPayload = BytesBuilder();
    hmacPayload.addByte(currentVersion);
    hmacPayload.add(salt);
    hmacPayload.add(iv.bytes);
    hmacPayload.add(encrypted.bytes);
    
    final hmac = _calculateHmac(hmacKey, hmacPayload.toBytes());

    // 5. Build final payload: [Version(1)] [Salt(16)] [IV(16)] [HMAC(32)] [Ciphertext]
    final finalPayload = BytesBuilder();
    finalPayload.addByte(currentVersion);
    finalPayload.add(salt);
    finalPayload.add(iv.bytes);
    finalPayload.add(hmac);
    finalPayload.add(encrypted.bytes);

    // 6. Write to temp file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/private_tracker_backup_${DateTime.now().millisecondsSinceEpoch}.enc');
    await file.writeAsBytes(finalPayload.toBytes());
    
    return file;
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
    final hmacPayload = BytesBuilder();
    hmacPayload.addByte(currentVersion);
    hmacPayload.add(salt);
    hmacPayload.add(iv.bytes);
    hmacPayload.add(ciphertext);
    
    final calculatedHmac = _calculateHmac(hmacKey, hmacPayload.toBytes());
    
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
    final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64));
    pbkdf2.init(pc.Pbkdf2Parameters(salt, 10000, 32));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  Future<Uint8List> _deriveHmacKeyFromPassword(String password, Uint8List salt) async {
    // Use a different iteration or salt variation for HMAC key derivation? 
    // For simplicity, we can use PBKDF2 with a distinct "purpose" suffix in the salt.
    final hmacSalt = Uint8List.fromList(salt + utf8.encode("HMAC_AUTH"));
    final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64));
    pbkdf2.init(pc.Pbkdf2Parameters(hmacSalt, 10000, 32));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
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
