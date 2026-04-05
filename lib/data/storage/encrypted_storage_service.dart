import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/symptom_log.dart';
import '../../domain/models/custom_tag.dart';
import 'secure_key_storage.dart';
import 'local_database_manager.dart';
import 'database_migrator.dart';
import 'backup_restore_service.dart';
import 'data_export_service.dart';

class EncryptedStorageService {
  final SecureKeyStorage _keyStorage;
  final LocalDatabaseManager _dbManager;
  final DatabaseMigrator _migrator;
  final BackupRestoreService _backupService;
  final DataExportService _exportService;

  EncryptedStorageService({
    required SecureKeyStorage keyStorage,
    required LocalDatabaseManager dbManager,
    required DatabaseMigrator migrator,
    required BackupRestoreService backupService,
    required DataExportService exportService,
  }) : _keyStorage = keyStorage,
       _dbManager = dbManager,
       _migrator = migrator,
       _backupService = backupService,
       _exportService = exportService;

  bool get isInitialized => _dbManager.isInitialized;

  // Box names (kept for mapping)
  static const String cycleLogBox = LocalDatabaseManager.cycleLogBox;
  static const String symptomLogBox = LocalDatabaseManager.symptomLogBox;
  static const String customTagBox = LocalDatabaseManager.customTagBox;

  /// Initializes Hive and the encrypted boxes.
  Future<void> initialize({String? basePath}) async {
    final encryptionKey = await _keyStorage.getOrCreateEncryptionKey();
    
    await _dbManager.initialize(
      basePath: basePath,
      encryptionKey: encryptionKey,
    ).timeout(const Duration(seconds: 10));

    // Run migrations
    await _migrator.migrateToUUIDs();
  }

  // Generic methods for CRUD
  Box<T> getBox<T>(String name) => _dbManager.getBox<T>(name);

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
  Box<CustomTag> getCustomTagsBox() => getBox<CustomTag>(customTagBox);

  /// Retrieves the symptom logs box.
  Box<SymptomLog> getSymptomLogsBox() => getBox<SymptomLog>(symptomLogBox);

  /// Retrieves the cycle logs box.
  Box<CycleEvent> getCycleLogsBox() => getBox<CycleEvent>(cycleLogBox);

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
    final box = getBox<CustomTag>(customTagBox);
    await box.delete(tag.id);
  }

  /// Exports all data to a CSV string.
  Future<String> exportDataToCsv() async {
    return _exportService.exportDataToCsv(
      cycleEvents: getCycleEvents(),
      symptomLogs: getSymptomLogs(),
    );
  }

  /// Exports all data to an encrypted and compressed (.enc) file.
  Future<File> exportEncryptedBackup(String userPassword) async {
    return _backupService.exportEncryptedBackup(
      userPassword: userPassword,
      cycleEvents: getCycleEvents(),
      symptomLogs: getSymptomLogs(),
      customTags: getCustomTagsBox().values.toList(),
    );
  }

  /// Imports and restores data from an encrypted backup file.
  Future<void> importEncryptedBackup(File file, String userPassword) async {
    final data = await _backupService.importEncryptedBackup(file, userPassword);
    await _restoreData(data);
  }

  Future<void> _restoreData(Map<String, dynamic> data) async {
    // Clear boxes
    await getBox<CycleEvent>(cycleLogBox).clear();
    await getBox<SymptomLog>(symptomLogBox).clear();
    await getBox<CustomTag>(customTagBox).clear();

    // Import Custom Tags first
    final customTagsBox = getBox<CustomTag>(customTagBox);
    final List<dynamic> tagsJson = data['customTags'] ?? [];
    for (var tagMap in tagsJson) {
      final tag = CustomTag.fromMap(Map<String, dynamic>.from(tagMap));
      await customTagsBox.put(tag.id, tag);
    }

    // Import Cycle Events
    final cycleLogBoxLocal = getBox<CycleEvent>(cycleLogBox);
    final List<dynamic> cycleLogsJson = data['cycleLogs'] ?? [];
    for (var logMap in cycleLogsJson) {
      final event = CycleEvent.fromMap(Map<String, dynamic>.from(logMap));
      await cycleLogBoxLocal.put(event.id, event);
    }

    // Import Symptom Logs
    final symptomLogBoxLocal = getBox<SymptomLog>(symptomLogBox);
    final List<dynamic> symptomLogsJson = data['symptomLogs'] ?? [];
    for (var logMap in symptomLogsJson) {
      final log = SymptomLog.fromMap(Map<String, dynamic>.from(logMap));
      await symptomLogBoxLocal.put(log.id, log);
    }
  }
}
