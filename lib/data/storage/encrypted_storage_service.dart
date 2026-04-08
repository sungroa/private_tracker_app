import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/custom_tag.dart';
import 'secure_key_storage.dart';
import 'local_database_manager.dart';
import 'backup_restore_service.dart';
import 'data_export_service.dart';
import 'data_sources/cycle_data_source.dart';
import 'data_sources/symptom_data_source.dart';
import 'data_sources/tag_data_source.dart';

class EncryptedStorageService {
  final SecureKeyStorage _keyStorage;
  final LocalDatabaseManager _dbManager;
  final BackupRestoreService _backupService;
  final DataExportService _exportService;
  
  final CycleDataSource _cycleDataSource;
  final SymptomDataSource _symptomDataSource;
  final TagDataSource _tagDataSource;

  EncryptedStorageService({
    required SecureKeyStorage keyStorage,
    required LocalDatabaseManager dbManager,
    required BackupRestoreService backupService,
    required DataExportService exportService,
    required CycleDataSource cycleDataSource,
    required SymptomDataSource symptomDataSource,
    required TagDataSource tagDataSource,
  }) : _keyStorage = keyStorage,
       _dbManager = dbManager,
       _backupService = backupService,
       _exportService = exportService,
       _cycleDataSource = cycleDataSource,
       _symptomDataSource = symptomDataSource,
       _tagDataSource = tagDataSource;

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
  }

  // Generic methods for CRUD (internal/limited use)
  Box<T> getBox<T>(String name) => _dbManager.getBox<T>(name);

  /// Exports all data to a CSV string.
  Future<String> exportDataToCsv() async {
    return _exportService.exportDataToCsv(
      cycleEvents: _cycleDataSource.getCycleEvents(),
      symptomLogs: _symptomDataSource.getAllSymptomLogs(),
    );
  }

  /// Exports all data to an encrypted and compressed (.enc) file.
  Future<File> exportEncryptedBackup(String userPassword) async {
    return _backupService.exportEncryptedBackup(
      userPassword: userPassword,
      cycleEvents: _cycleDataSource.getCycleEvents(),
      symptomLogs: _symptomDataSource.getAllSymptomLogs(),
      customTags: _tagDataSource.getCustomTags(),
    );
  }

  /// Imports and restores data from an encrypted backup file.
  Future<void> importEncryptedBackup(File file, String userPassword) async {
    final data = await _backupService.importEncryptedBackup(file, userPassword);
    await _restoreData(data);
  }

  Future<void> _restoreData(Map<String, dynamic> data) async {
    // Clear boxes
    await _cycleDataSource.clear();
    await _symptomDataSource.clear();
    await _tagDataSource.clear();

    // Import Custom Tags first
    final List<dynamic> tagsJson = data['customTags'] ?? [];
    for (var tagMap in tagsJson) {
      final tag = CustomTag.fromMap(Map<String, dynamic>.from(tagMap));
      await _tagDataSource.addCustomTag(tag.name);
    }

    // Import Cycle Events
    final List<dynamic> cycleLogsJson = data['cycleLogs'] ?? [];
    for (var logMap in cycleLogsJson) {
      final event = CycleEvent.fromMap(Map<String, dynamic>.from(logMap));
      await _cycleDataSource.saveCycleEvent(event);
    }

    // Import Symptom Logs
    final List<dynamic> symptomLogsJson = data['symptomLogs'] ?? [];
    for (var logMap in symptomLogsJson) {
      final log = SymptomLog.fromMap(Map<String, dynamic>.from(logMap));
      await _symptomDataSource.saveSymptomLog(log);
    }
  }
}
