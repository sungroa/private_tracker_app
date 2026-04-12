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
import 'package:private_tracker_app/domain/models/symptom_log.dart';


/// High-level orchestration service for all persistence and security operations.
/// 
/// [EncryptedStorageService] serves as the primary entry point for managing data lifecycle,
/// including initialization, backup/restore, and CSV exports. It coordinates multiple
/// specialized [LocalDataSource] objects and security services.
/// 
/// This service implements a "Zero-Knowledge" storage strategy where all data is 
/// encrypted on-device using AES-256 before being written to disk.
class EncryptedStorageService {
  final SecureKeyStorage _keyStorage;
  final LocalDatabaseManager _dbManager;
  final BackupRestoreService _backupService;
  final DataExportService _exportService;
  
  final CycleDataSource _cycleDataSource;
  final SymptomDataSource _symptomDataSource;
  final TagDataSource _tagDataSource;

  /// Injected constructor to support Dependency Injection (DI) and testability.
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

  /// Returns true if the underlying database manager has completed initialization.
  bool get isInitialized => _dbManager.isInitialized;

  // Internal mapping of box names for Hive orchestration.
  static const String cycleLogBox = LocalDatabaseManager.cycleLogBox;
  static const String symptomLogBox = LocalDatabaseManager.symptomLogBox;
  static const String customTagBox = LocalDatabaseManager.customTagBox;

  /// Initializes the Hive database, secure key storage, and opens encrypted boxes.
  /// 
  /// The process involves:
  /// 1. retrieving or generating a 256-bit AES encryption key via [_keyStorage].
  /// 2. Initializing [Hive] and registering type adapters.
  /// 3. Opening encrypted boxes using the retrieved key.
  /// 
  /// [basePath] Optional override for the database directory (primarily for testing).
  Future<void> initialize({String? basePath}) async {
    final encryptionKey = await _keyStorage.getOrCreateEncryptionKey();
    
    await _dbManager.initialize(
      basePath: basePath,
      encryptionKey: encryptionKey,
    ).timeout(const Duration(seconds: 10));
  }

  /// Low-level access to a specific Hive box. Use with caution.
  Box<T> getBox<T>(String name) => _dbManager.getBox<T>(name);

  /// Aggregates all user logs and produces a human-readable CSV string.
  /// Delegates to [DataExportService].
  Future<String> exportDataToCsv() async {
    return _exportService.exportDataToCsv(
      cycleEvents: _cycleDataSource.getCycleLogs(),
      symptomLogs: _symptomDataSource.getAllSymptomLogs(),
    );
  }

  /// Creates a password-protected, AES-encrypted, and GZIP-compressed backup file.
  /// Delegates to [BackupRestoreService].
  /// 
  /// [userPassword] The password provided by the user to derive a KEK (Key Encryption Key).
  Future<File> exportEncryptedBackup(String userPassword) async {
    return _backupService.exportEncryptedBackup(
      userPassword: userPassword,
      cycleEvents: _cycleDataSource.getCycleLogs(),
      symptomLogs: _symptomDataSource.getAllSymptomLogs(),
      customTags: _tagDataSource.getCustomTags(),
    );
  }

  /// Decrypts and restores application state from a [.enc] backup file.
  /// 
  /// WARNING: This operation wipes all current local data before importing backup contents.
  Future<void> importEncryptedBackup(File file, String userPassword) async {
    final data = await _backupService.importEncryptedBackup(file, userPassword);
    await _restoreData(data);
  }

  /// Internal helper to atomically update local storage with restored data.
  Future<void> _restoreData(Map<String, dynamic> data) async {
    // 1. Wipe current state to ensure a clean restoration
    await _cycleDataSource.clear();
    await _symptomDataSource.clear();
    await _tagDataSource.clear();

    // 2. Import Custom Tags first (dependencies for symptom logs)
    final List<dynamic> tagsJson = data['customTags'] ?? [];
    for (var tagMap in tagsJson) {
      final tag = CustomTag.fromMap(Map<String, dynamic>.from(tagMap));
      await _tagDataSource.addCustomTag(tag.name);
    }

    // 3. Import Cycle Logs
    final List<dynamic> cycleLogsJson = data['cycleLogs'] ?? [];
    for (var logMap in cycleLogsJson) {
      final event = CycleLog.fromMap(Map<String, dynamic>.from(logMap));
      await _cycleDataSource.saveCycleLog(event);
    }

    // 4. Import Symptom Logs
    final List<dynamic> symptomLogsJson = data['symptomLogs'] ?? [];
    for (var logMap in symptomLogsJson) {
      final log = SymptomLog.fromMap(Map<String, dynamic>.from(logMap));
      await _symptomDataSource.saveSymptomLog(log);
    }
  }
}
