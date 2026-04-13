import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/custom_tag.dart';
import 'secure_key_storage.dart';
import 'local_database_manager.dart';
import 'data_sources/cycle_data_source.dart';
import 'data_sources/symptom_data_source.dart';
import 'data_sources/tag_data_source.dart';
import 'hive_dtos.dart';
import 'model_mapper.dart';
import 'data_export_service.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';

/// Core storage service focused on initialization and low-level data access.
/// 
/// High-level orchestration for backup and sync is handled by [BackupOrchestrator].
class EncryptedStorageService {
  final SecureKeyStorage _keyStorage;
  final LocalDatabaseManager _dbManager;
  final DataExportService _exportService;
  
  final CycleDataSource _cycleDataSource;
  final SymptomDataSource _symptomDataSource;
  final TagDataSource _tagDataSource;

  EncryptedStorageService({
    required SecureKeyStorage keyStorage,
    required LocalDatabaseManager dbManager,
    required DataExportService exportService,
    required CycleDataSource cycleDataSource,
    required SymptomDataSource symptomDataSource,
    required TagDataSource tagDataSource,
  }) : _keyStorage = keyStorage,
       _dbManager = dbManager,
       _exportService = exportService,
       _cycleDataSource = cycleDataSource,
       _symptomDataSource = symptomDataSource,
       _tagDataSource = tagDataSource;

  bool get isInitialized => _dbManager.isInitialized;

  /// Initializes the Hive database and encryption.
  Future<void> initialize({String? basePath}) async {
    final encryptionKey = await _keyStorage.getOrCreateEncryptionKey();
    
    await _dbManager.initialize(
      basePath: basePath,
      encryptionKey: encryptionKey,
    ).timeout(const Duration(seconds: 10));
  }

  /// Low-level access to a specific Hive box.
  Box<T> getBox<T>(String name) => _dbManager.getBox<T>(name);

  /// Aggregates all user logs for CSV export.
  Future<String> exportDataToCsv() async {
    return _exportService.exportDataToCsv(
      cycleEvents: _cycleDataSource.getCycleLogs(),
      symptomLogs: _symptomDataSource.getAllSymptomLogs(),
    );
  }

  /// Serializes all current data into a Map.
  Map<String, dynamic> getAllDataAsMap() {
    return {
      'cycleLogs': _cycleDataSource.getCycleLogs().map((l) => ModelMapper.cycleLogToMap(l)).toList(),
      'symptomLogs': _symptomDataSource.getAllSymptomLogs().map((l) => ModelMapper.symptomLogToMap(l)).toList(),
      'customTags': _tagDataSource.getCustomTags().map((t) => ModelMapper.customTagToMap(t)).toList(),
    };
  }

  /// Bulk persistence of domain models.
  Future<void> persistMergedData({
    required List<CycleLog> cycleLogs,
    required List<SymptomLog> symptomLogs,
    required List<CustomTag> customTags,
  }) async {
    if (customTags.isNotEmpty) {
      await _tagDataSource.putAll({
        for (var tag in customTags) tag.id: CustomTagDto.fromDomain(tag)
      });
    }
    
    if (cycleLogs.isNotEmpty) {
      await _cycleDataSource.putAll({
        for (var log in cycleLogs) log.id: CycleLogDto.fromDomain(log)
      });
    }
    
    if (symptomLogs.isNotEmpty) {
      await _symptomDataSource.putAll({
        for (var log in symptomLogs) log.id: SymptomLogDto.fromDomain(log)
      });
    }
    
    await _dbManager.updateLastModified();
  }
}
