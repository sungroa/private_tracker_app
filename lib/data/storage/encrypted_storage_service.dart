import '../../domain/models/cycle_log.dart';
import '../../domain/models/custom_tag.dart';
import 'secure_key_storage.dart';
import 'local_database_manager.dart';
import 'data_sources/cycle_data_source.dart';
import 'data_sources/symptom_data_source.dart';
import 'data_sources/tag_data_source.dart';
import 'data_sources/data_seeding_service.dart';
import 'model_mapper.dart';
import 'data_export_service.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';

/// Core storage service responsible for secure database lifecycle management.
/// 
/// 🏛️ **Architecture**: This service acts as the bridge between low-level Hive
/// data sources and the domain models. It coordinates encryption key retrieval
/// from [SecureKeyStorage] and data seeding via [DataSeedingService].
/// 
/// 🔒 **Security**: All data persisted through this service is encrypted using 
/// the platform-specific master key. It maintains the "Zero-Knowledge" guarantee
/// by ensuring raw data only exists in memory during active use.
class EncryptedStorageService {
  final SecureKeyStorage _keyStorage;
  final LocalDatabaseManager _dbManager;
  final DataExportService _exportService;
  final DataSeedingService _seedingService;
  
  final CycleDataSource _cycleDataSource;
  final SymptomDataSource _symptomDataSource;
  final TagDataSource _tagDataSource;

  EncryptedStorageService({
    required this._keyStorage,
    required this._dbManager,
    required this._exportService,
    required this._seedingService,
    required this._cycleDataSource,
    required this._symptomDataSource,
    required this._tagDataSource,
  });

  bool get isInitialized => _dbManager.isInitialized;

  /// Initializes the Hive database and encryption.
  Future<void> initialize({String? basePath}) async {
    final encryptionKey = await _keyStorage.getOrCreateEncryptionKey();
    
    await _dbManager.initialize(
      basePath: basePath,
      encryptionKey: encryptionKey,
    );

    // Seed default data if necessary (SRP decoupled from DB manager)
    await _seedingService.seedDefaultTags(_tagDataSource.box);
  }

  /// Aggregates all user logs for CSV export.
  Future<String> exportDataToCsv() async {
    return _exportService.exportDataToCsv(
      cycleEvents: await _cycleDataSource.getCycleLogs(),
      symptomLogs: await _symptomDataSource.getSymptomLogs(),
      customTags: await _tagDataSource.getCustomTags(),
    );
  }

  /// Serializes all current data into a Map for sync/backup.
  Future<Map<String, dynamic>> getAllDataAsMap() async {
    return _exportService.exportAllDataAsJsonReadyMap(
      cycleLogs: await _cycleDataSource.getCycleLogs(),
      symptomLogs: await _symptomDataSource.getSymptomLogs(),
      customTags: await _tagDataSource.getCustomTags(),
    );
  }

  /// Bulk persistence of domain models.
  Future<void> persistMergedData({
    required List<CycleLog> cycleLogs,
    required List<SymptomLog> symptomLogs,
    required List<CustomTag> customTags,
  }) async {
    if (customTags.isNotEmpty) {
      await _tagDataSource.putAll({
        for (var tag in customTags) tag.id: ModelMapper.customTagToDto(tag)
      });
    }
    
    if (cycleLogs.isNotEmpty) {
      await _cycleDataSource.putAll({
        for (var log in cycleLogs) log.id: ModelMapper.cycleLogToDto(log)
      });
    }
    
    if (symptomLogs.isNotEmpty) {
      await _symptomDataSource.putAll({
        for (var log in symptomLogs) log.id: ModelMapper.symptomLogToDto(log)
      });
    }
    
    await _dbManager.updateLastModified();
  }
}
