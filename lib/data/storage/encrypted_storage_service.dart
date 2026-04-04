import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:meta/meta.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:uuid/uuid.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/custom_tag.dart';

class EncryptedStorageService {
  static const String _encryptionKeyName = 'hive_encryption_key_v1';
  
  final FlutterSecureStorage _secureStorage;
  bool _isInitialized = false;

  // Singleton instance
  static EncryptedStorageService _instance = EncryptedStorageService._internal(
    const FlutterSecureStorage(),
  );

  static EncryptedStorageService get instance => _instance;

  @visibleForTesting
  static set instance(EncryptedStorageService mock) => _instance = mock;

  @visibleForTesting
  static void resetForTesting() {
    _instance = EncryptedStorageService._internal(const FlutterSecureStorage());
  }

  EncryptedStorageService._internal(this._secureStorage);

  // For testing
  EncryptedStorageService.test(this._secureStorage);

  // Box names
  static const String cycleLogBox = 'cycle_logs';
  static const String symptomLogBox = 'symptom_logs';
  static const String customTagBox = 'custom_tags';

  /// Initializes Hive and the encrypted boxes.
  Future<void> initialize({String? basePath}) async {
    // If already initialized and boxes are open, we can skip.
    // In tests, boxes might be closed between runs while the singleton persists.
    if (_isInitialized && Hive.isBoxOpen(symptomLogBox)) return;
    
    if (basePath != null) {
      Hive.init(basePath);
    } else {
      await Hive.initFlutter();
    }

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CycleLogAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SymptomLogAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CustomTagAdapter());

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
    await Hive.openBox<CustomTag>(
      customTagBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    // Pre-populate defaults if empty
    await _initializeDefaultTags();

    // Migrate existing records to UUIDs
    await _migrateToUUIDs();
    
    _isInitialized = true;
  }

  Future<void> _initializeDefaultTags() async {
    final box = Hive.box<CustomTag>(customTagBox);
    if (box.isEmpty) {
      final defaults = [
        'Cramps',
        'Bloating',
        'Acne',
        'Headache',
        'Mood Swings',
        'Fatigue',
      ];
      for (var name in defaults) {
        final tag = CustomTag(name: name, isDefault: true);
        await box.put(tag.id, tag);
      }
    }
  }

  Future<void> _migrateToUUIDs() async {
    // Migrate Cycle Logs
    final cycleBox = Hive.box<CycleLog>(cycleLogBox);
    for (var key in cycleBox.keys.toList()) {
      final log = cycleBox.get(key);
      if (log != null && log.id.isEmpty) {
        final newLog = CycleLog(
          id: const Uuid().v4(),
          startDate: log.startDate,
          endDate: log.endDate,
          notes: log.notes,
        );
        await cycleBox.put(newLog.id, newLog);
        if (key != newLog.id) {
          await cycleBox.delete(key);
        }
      } else if (log != null && key != log.id) {
        await cycleBox.put(log.id, log);
        await cycleBox.delete(key);
      }
    }

    // Migrate Symptom Logs
    final symptomBox = Hive.box<SymptomLog>(symptomLogBox);
    for (var key in symptomBox.keys.toList()) {
      final log = symptomBox.get(key);
      if (log != null && log.id.isEmpty) {
        final newLog = SymptomLog(
          id: const Uuid().v4(),
          date: log.date,
          symptoms: log.symptoms,
          moodRating: log.moodRating,
          notes: log.notes,
          basalBodyTemperature: log.basalBodyTemperature,
          cervicalFluidType: log.cervicalFluidType,
          lhTestPositive: log.lhTestPositive,
        );
        await symptomBox.put(newLog.id, newLog);
        if (key != newLog.id) {
          await symptomBox.delete(key);
        }
      } else if (log != null && key != log.id) {
        await symptomBox.put(log.id, log);
        await symptomBox.delete(key);
      }
    }

    // Migrate Custom Tags
    final tagBox = Hive.box<CustomTag>(customTagBox);
    for (var key in tagBox.keys.toList()) {
      final tag = tagBox.get(key);
      if (tag != null && tag.id.isEmpty) {
        final newTag = CustomTag(
          id: const Uuid().v4(),
          name: tag.name,
          isDefault: tag.isDefault,
        );
        await tagBox.put(newTag.id, newTag);
        if (key != newTag.id) {
          await tagBox.delete(key);
        }
      } else if (tag != null && key != tag.id) {
        await tagBox.put(tag.id, tag);
        await tagBox.delete(key);
      }
    }
  }

  /// Securely retrieves the existing encryption key or generates a new one.
  Future<List<int>> _getOrCreateEncryptionKey() async {
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
  Box<T> getBox<T>(String name) => Hive.box<T>(name);

  /// Saves or updates a symptom log.
  Future<void> saveSymptomLog(SymptomLog log) async {
    final box = getBox<SymptomLog>(symptomLogBox);
    await box.put(log.id, log);
  }

  /// Deletes a symptom log by id.
  Future<void> deleteSymptomLog(String id) async {
    final box = getBox<SymptomLog>(symptomLogBox);
    await box.delete(id);
  }

  /// Saves or updates a cycle log.
  Future<void> saveCycleLog(CycleLog log) async {
    final box = getBox<CycleLog>(cycleLogBox);
    await box.put(log.id, log);
  }

  /// Deletes a cycle log by id.
  Future<void> deleteCycleLog(String id) async {
    final box = getBox<CycleLog>(cycleLogBox);
    await box.delete(id);
  }

  /// Retrieves all symptom logs for a specific month.
  List<SymptomLog> getSymptomLogsForMonth(DateTime month) {
    final box = getBox<SymptomLog>(symptomLogBox);
    return box.values.where((log) => 
      log.date.year == month.year && log.date.month == month.month
    ).toList();
  }

  /// Retrieves all cycle logs sorted by start date.
  List<CycleLog> getCycleLogs() {
    final box = getBox<CycleLog>(cycleLogBox);
    final logs = box.values.toList();
    logs.sort((a, b) => b.startDate.compareTo(a.startDate)); // Newest first
    return logs;
  }

  /// Retrieves all symptom logs.
  List<SymptomLog> getSymptomLogs() {
    final box = getBox<SymptomLog>(symptomLogBox);
    return box.values.toList();
  }

  /// Retrieves the custom tags box.
  Box<CustomTag> getCustomTagsBox() => Hive.box<CustomTag>(customTagBox);

  /// Adds a new custom tag.
  Future<void> addCustomTag(String name) async {
    final box = getCustomTagsBox();
    if (box.values.any((tag) => tag.name.toLowerCase() == name.toLowerCase())) {
      return;
    }
    final newTag = CustomTag(name: name);
    await box.put(newTag.id, newTag);
  }

  /// Deletes a custom tag.
  Future<void> deleteCustomTag(CustomTag tag) async {
    await tag.delete();
  }

  /// Exports all data to a CSV string.
  Future<String> exportDataToCsv() async {
    final List<List<dynamic>> rows = [];
    rows.add(['Log Type', 'Start Date/Date', 'End Date', 'Symptoms', 'Mood Rating', 'BBT', 'Fluid', 'LH Test', 'Notes']);
    
    final cycleLogs = getCycleLogs();
    for (var log in cycleLogs) {
      rows.add([
        'Cycle',
        log.startDate.toIso8601String().split('T')[0],
        log.endDate?.toIso8601String().split('T')[0] ?? '',
        '',
        '',
        '',
        '',
        '',
        log.notes ?? '',
      ]);
    }
    
    final symptomLogs = getSymptomLogs();
    for (var log in symptomLogs) {
      rows.add([
        'Symptom',
        log.date.toIso8601String().split('T')[0],
        '',
        log.symptoms.join('; '),
        log.moodRating.toString(),
        log.basalBodyTemperature?.toString() ?? '',
        log.cervicalFluidType ?? '',
        log.lhTestPositive == true ? 'Positive' : (log.lhTestPositive == false ? 'Negative' : ''),
        log.notes ?? '',
      ]);
    }
    
    return csv.encode(rows);
  }

  // --- Encrypted Backup & Restore Implementation ---

  /// Exports all data to an encrypted and compressed (.enc) file.
  Future<File> exportEncryptedBackup(String userPassword) async {
    // 1. Serialize all data
    final data = {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'cycleLogs': getCycleLogs().map((l) => l.toMap()).toList(),
      'symptomLogs': getSymptomLogs().map((l) => l.toMap()).toList(),
      'customTags': getBox<CustomTag>(customTagBox).values.map((t) => t.toMap()).toList(),
    };

    final jsonString = jsonEncode(data);

    // 2. Compress (GZip)
    final jsonBytes = utf8.encode(jsonString);
    final compressedBytes = GZipEncoder().encode(jsonBytes);
    if (compressedBytes == null) throw Exception("Compression failed");

    // 3. Encrypt (AES-256-CBC)
    final salt = encrypt.IV.fromSecureRandom(16).bytes;
    final iv = encrypt.IV.fromSecureRandom(16);
    
    final keyBytes = await _deriveKeyFromPassword(userPassword, Uint8List.fromList(salt));
    final key = encrypt.Key(keyBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    
    final encrypted = encrypter.encryptBytes(compressedBytes, iv: iv);

    // 4. Build payload: [Salt(16)] [IV(16)] [Ciphertext]
    final payload = BytesBuilder();
    payload.add(salt);
    payload.add(iv.bytes);
    payload.add(encrypted.bytes);

    // 5. Write to temp file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/private_tracker_backup_${DateTime.now().millisecondsSinceEpoch}.enc');
    await file.writeAsBytes(payload.toBytes());
    
    return file;
  }

  /// Imports and restores data from an encrypted backup file.
  Future<void> importEncryptedBackup(File file, String userPassword) async {
    final bytes = await file.readAsBytes();
    if (bytes.length < 32) throw Exception("Invalid backup file: too small");

    // 1. Extract Salt, IV, and Ciphertext
    final salt = bytes.sublist(0, 16);
    final iv = encrypt.IV(bytes.sublist(16, 32));
    final ciphertext = bytes.sublist(32);

    // 2. Decrypt
    final List<int> decryptedBytes;
    try {
      final keyBytes = await _deriveKeyFromPassword(userPassword, salt);
      final key = encrypt.Key(keyBytes);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      decryptedBytes = encrypter.decryptBytes(encrypt.Encrypted(ciphertext), iv: iv);
    } catch (e) {
      throw Exception("Decryption failed: possible incorrect password or corrupted file");
    }

    // 3. Decompress
    final List<int> decompressedBytes;
    try {
      decompressedBytes = GZipDecoder().decodeBytes(decryptedBytes);
    } catch (e) {
      throw Exception("Decompression failed: corrupted data");
    }

    final jsonString = utf8.decode(decompressedBytes);
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonString);
    } catch (e) {
      throw Exception("Invalid backup format: not a valid JSON");
    }

    // 4. Validate Version (Basic check)
    if (data['version'] == null) throw Exception("Invalid backup format: missing version");
    
    // 5. Clear and Restore
    await _restoreData(data);
  }

  Future<Uint8List> _deriveKeyFromPassword(String password, Uint8List salt) async {
    // We use PointyCastle's PBKDF2 for strong key derivation.
    // iteration count: 10,000 is a reasonable balance for mobile performance vs security.
    final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64));
    pbkdf2.init(pc.Pbkdf2Parameters(salt, 10000, 32));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  Future<void> _restoreData(Map<String, dynamic> data) async {
    // Clear boxes
    await Hive.box<CycleLog>(cycleLogBox).clear();
    await Hive.box<SymptomLog>(symptomLogBox).clear();
    await Hive.box<CustomTag>(customTagBox).clear();

    // Import Custom Tags first (to maintain defaults behavior)
    final customTagsBox = Hive.box<CustomTag>(customTagBox);
    final List<dynamic> tagsJson = data['customTags'] ?? [];
    for (var tagMap in tagsJson) {
      await customTagsBox.add(CustomTag.fromMap(Map<String, dynamic>.from(tagMap)));
    }

    // Import Cycle Logs
    final cycleLogBoxLocal = Hive.box<CycleLog>(cycleLogBox);
    final List<dynamic> cycleLogsJson = data['cycleLogs'] ?? [];
    for (var logMap in cycleLogsJson) {
      await cycleLogBoxLocal.add(CycleLog.fromMap(Map<String, dynamic>.from(logMap)));
    }

    // Import Symptom Logs
    final symptomLogBoxLocal = Hive.box<SymptomLog>(symptomLogBox);
    final List<dynamic> symptomLogsJson = data['symptomLogs'] ?? [];
    for (var logMap in symptomLogsJson) {
      final log = SymptomLog.fromMap(Map<String, dynamic>.from(logMap));
      await symptomLogBoxLocal.put(log.id, log);
    }
  }
}
