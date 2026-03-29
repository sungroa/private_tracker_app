import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/custom_tag.dart';


class EncryptedStorageService {
  static const String _encryptionKeyName = 'hive_encryption_key_v1';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Box names
  static const String cycleLogBox = 'cycle_logs';
  static const String symptomLogBox = 'symptom_logs';
  static const String customTagBox = 'custom_tags';


  /// Initializes Hive and the encrypted boxes.
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(CycleLogAdapter());
    Hive.registerAdapter(SymptomLogAdapter());
    Hive.registerAdapter(CustomTagAdapter());


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
  }

  static Future<void> _initializeDefaultTags() async {
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

  /// Saves or updates a symptom log.
  /// Uses the date (YYYY-MM-DD) as the key to ensure one log per day.
  static Future<void> saveSymptomLog(SymptomLog log) async {
    final box = getBox<SymptomLog>(symptomLogBox);
    final key = "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}";
    await box.put(key, log);
  }

  /// Saves or updates a cycle log.
  static Future<void> saveCycleLog(CycleLog log) async {
    final box = getBox<CycleLog>(cycleLogBox);
    if (log.isInBox) {
      await log.save();
    } else {
      await box.add(log);
    }
  }

  /// Retrieves all symptom logs for a specific month.
  static List<SymptomLog> getSymptomLogsForMonth(DateTime month) {
    final box = getBox<SymptomLog>(symptomLogBox);
    return box.values.where((log) => 
      log.date.year == month.year && log.date.month == month.month
    ).toList();
  }

  /// Retrieves all cycle logs sorted by start date.
  static List<CycleLog> getCycleLogs() {
    final box = getBox<CycleLog>(cycleLogBox);
    final logs = box.values.toList();
    logs.sort((a, b) => b.startDate.compareTo(a.startDate)); // Newest first
    return logs;
  }

  /// Retrieves all symptom logs.
  static List<SymptomLog> getSymptomLogs() {
    final box = getBox<SymptomLog>(symptomLogBox);
    return box.values.toList();
  }

  /// Retrieves the custom tags box.
  static Box<CustomTag> getCustomTagsBox() => Hive.box<CustomTag>(customTagBox);

  /// Adds a new custom tag.
  static Future<void> addCustomTag(String name) async {
    final box = getCustomTagsBox();
    // Check for duplicates
    if (box.values.any((tag) => tag.name.toLowerCase() == name.toLowerCase())) {
      return;
    }
    await box.add(CustomTag(name: name));
  }

  /// Deletes a custom tag.
  static Future<void> deleteCustomTag(CustomTag tag) async {
    await tag.delete();
  }

  /// Exports all data to a CSV string.
  static Future<String> exportDataToCsv() async {
    final List<List<dynamic>> rows = [];
    
    // Add Headers
    rows.add(['Log Type', 'Start Date/Date', 'End Date', 'Symptoms', 'Mood Rating', 'BBT', 'Fluid', 'LH Test', 'Notes']);
    
    // Cycle Logs
    final cycleLogs = getCycleLogs();
    for (var log in cycleLogs) {
      rows.add([
        'Cycle',
        log.startDate.toIso8601String().split('T')[0],
        log.endDate?.toIso8601String().split('T')[0] ?? '',
        '', // Symptoms not applicable
        '', // Mood Rating not applicable
        '', // BBT
        '', // Fluid
        '', // LH
        log.notes ?? '',
      ]);
    }
    
    // Symptom Logs
    final symptomLogs = getSymptomLogs();
    for (var log in symptomLogs) {
      rows.add([
        'Symptom',
        log.date.toIso8601String().split('T')[0],
        '', // End Date not applicable
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
}
