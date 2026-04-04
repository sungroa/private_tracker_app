import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:meta/meta.dart';
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

  EncryptedStorageService._internal(this._secureStorage);

  // For testing
  EncryptedStorageService.test(this._secureStorage);

  // Box names
  static const String cycleLogBox = 'cycle_logs';
  static const String symptomLogBox = 'symptom_logs';
  static const String customTagBox = 'custom_tags';

  /// Initializes Hive and the encrypted boxes.
  Future<void> initialize({String? basePath}) async {
    if (_isInitialized) return;
    
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
        await box.add(CustomTag(name: name, isDefault: true));
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
    final key = "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}";
    await box.put(key, log);
  }

  /// Saves or updates a cycle log.
  Future<void> saveCycleLog(CycleLog log) async {
    final box = getBox<CycleLog>(cycleLogBox);
    if (log.isInBox) {
      await log.save();
    } else {
      await box.add(log);
    }
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
    await box.add(CustomTag(name: name));
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
}
