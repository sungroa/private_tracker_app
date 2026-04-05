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

  bool get isInitialized => _isInitialized;

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
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CycleEventAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SymptomLogAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CustomTagAdapter());

    // Generate or fetch encryption key
    final encryptionKey = await _getOrCreateEncryptionKey();

    // Open boxes with encryption
    await Hive.openBox<CycleEvent>(
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

    // Open meta box for migration tracking (unencrypted, stores only flags)
    await Hive.openBox<String>('meta');

    // Migrate existing records to UUIDs (skipped if already done)
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
    final metaBox = Hive.box<String>('meta');
    if (metaBox.get('migration_v1') == 'done') return;

    // Migrate Cycle Events
    final cycleBox = Hive.box<CycleEvent>(cycleLogBox);
    for (var key in cycleBox.keys.toList()) {
      final log = cycleBox.get(key);
      if (log != null && log.id.isEmpty) {
        final newLog = CycleEvent(
          id: const Uuid().v4(),
          startDate: log.startDate,
          endDate: log.endDate,
          notes: log.notes,
          flowIntensity: 3, // Default for migrated
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
      }
    }
    // Mark migration as complete to avoid redundant scans
    await metaBox.put('migration_v1', 'done');
  }

  /// Securely retrieves the existing encryption key or generates a new one.
  /// Eliminates TOCTOU race by reading first, then generating if absent.
  Future<List<int>> _getOrCreateEncryptionKey() async {
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

  /// Saves or updates a cycle event.
  Future<void> saveCycleEvent(CycleEvent event) async {
    final box = getBox<CycleEvent>(cycleLogBox);
    await box.put(event.id, event);
  }

  /// Deletes a cycle event by id.
  Future<void> deleteCycleEvent(String id) async {
    final box = getBox<CycleEvent>(cycleLogBox);
    await box.delete(id);
  }

  /// Retrieves all symptom logs for a specific month.
  List<SymptomLog> getSymptomLogsForMonth(DateTime month) {
    final box = getBox<SymptomLog>(symptomLogBox);
    return box.values.where((log) => 
      log.date.year == month.year && log.date.month == month.month
    ).toList();
  }

  /// Retrieves all cycle events sorted by start date.
  List<CycleEvent> getCycleEvents() {
    final box = getBox<CycleEvent>(cycleLogBox);
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

  /// Retrieves the symptom logs box.
  Box<SymptomLog> getSymptomLogsBox() => Hive.box<SymptomLog>(symptomLogBox);

  /// Retrieves the cycle logs box.
  Box<CycleEvent> getCycleLogsBox() => Hive.box<CycleEvent>(cycleLogBox);

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
    final box = Hive.box<CustomTag>(customTagBox);
    await box.delete(tag.id);
  }

  /// Exports all data to a CSV string.
  Future<String> exportDataToCsv() async {
    final List<List<dynamic>> rows = [];
    rows.add(['Log Type', 'Start Date/Date', 'End Date', 'Symptoms', 'Mood Rating', 'BBT', 'Fluid', 'LH Test', 'Notes']);
    
    final List<CycleEvent> cycleEvents = getCycleEvents();
    for (var log in cycleEvents) {
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
    
    return Csv().encode(rows);
  }

  // --- Encrypted Backup & Restore Implementation ---

  /// Exports all data to an encrypted and compressed (.enc) file.
  Future<File> exportEncryptedBackup(String userPassword) async {
    // 1. Serialize all data
    final data = {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'cycleLogs': getCycleEvents().map((l) => l.toMap()).toList(),
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
    await Hive.box<CycleEvent>(cycleLogBox).clear();
    await Hive.box<SymptomLog>(symptomLogBox).clear();
    await Hive.box<CustomTag>(customTagBox).clear();

    // Import Custom Tags first (to maintain defaults behavior)
    final customTagsBox = Hive.box<CustomTag>(customTagBox);
    final List<dynamic> tagsJson = data['customTags'] ?? [];
    for (var tagMap in tagsJson) {
      final tag = CustomTag.fromMap(Map<String, dynamic>.from(tagMap));
      await customTagsBox.put(tag.id, tag);
    }

    // Import Cycle Events
    final cycleLogBoxLocal = Hive.box<CycleEvent>(cycleLogBox);
    final List<dynamic> cycleLogsJson = data['cycleLogs'] ?? [];
    for (var logMap in cycleLogsJson) {
      final event = CycleEvent.fromMap(Map<String, dynamic>.from(logMap));
      await cycleLogBoxLocal.put(event.id, event);
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
