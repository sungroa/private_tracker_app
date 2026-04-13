import 'dart:io';
import 'dart:typed_data';
import '../../domain/models/custom_tag.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/symptom_log.dart';
import 'backup_restore_service.dart';
import 'data_sources/cycle_data_source.dart';
import 'data_sources/symptom_data_source.dart';
import 'data_sources/tag_data_source.dart';
import 'hive_dtos.dart';
import 'local_database_manager.dart';
import 'model_mapper.dart';

/// specialized service to orchestrate backup and restore operations.
/// 
/// Decoupled from [EncryptedStorageService] to satisfy SRP.
class BackupOrchestrator {
  final BackupRestoreService _backupService;
  final LocalDatabaseManager _dbManager;
  final CycleDataSource _cycleDataSource;
  final SymptomDataSource _symptomDataSource;
  final TagDataSource _tagDataSource;

  BackupOrchestrator({
    required BackupRestoreService backupService,
    required LocalDatabaseManager dbManager,
    required CycleDataSource cycleDataSource,
    required SymptomDataSource symptomDataSource,
    required TagDataSource tagDataSource,
  }) : _backupService = backupService,
       _dbManager = dbManager,
       _cycleDataSource = cycleDataSource,
       _symptomDataSource = symptomDataSource,
       _tagDataSource = tagDataSource;

  /// Creates a password-protected, AES-encrypted, and GZIP-compressed backup file.
  Future<File> exportEncryptedBackup(String userPassword) async {
    return _backupService.exportEncryptedBackup(
      userPassword: userPassword,
      cycleEvents: _cycleDataSource.getCycleLogs(),
      symptomLogs: _symptomDataSource.getAllSymptomLogs(),
      customTags: _tagDataSource.getCustomTags(),
    );
  }

  /// Decrypts and restores application state from a [.enc] backup file.
  Future<void> importEncryptedBackup(File file, String userPassword) async {
    final data = await _backupService.importEncryptedBackup(file, userPassword);
    await restoreData(data);
  }

  /// Exports a cloud-specific backup using a persistent secret key.
  Future<Uint8List> exportCloudBackup(List<int> cloudKey) async {
    return _backupService.exportBackupWithKey(
      encryptionKey: cloudKey,
      cycleEvents: _cycleDataSource.getCycleLogs(),
      symptomLogs: _symptomDataSource.getAllSymptomLogs(),
      customTags: _tagDataSource.getCustomTags(),
    );
  }

  /// Imports a cloud-specific backup using a persistent secret key.
  Future<void> importCloudBackup(Uint8List payload, List<int> cloudKey) async {
    final data = await _backupService.importBackupWithKey(payload, cloudKey);
    await restoreData(data);
  }

  /// Low-level decryption of a backup payload into a raw Map.
  Future<Map<String, dynamic>> importBackupWithKey(Uint8List payload, List<int> cloudKey) async {
    return await _backupService.importBackupWithKey(payload, cloudKey);
  }

  /// Atomically update local storage with restored data.
  Future<void> restoreData(Map<String, dynamic> data) async {
    final List<dynamic> tagsJson = data['customTags'] ?? [];
    final List<dynamic> cycleLogsJson = data['cycleLogs'] ?? [];
    final List<dynamic> symptomLogsJson = data['symptomLogs'] ?? [];

    if (tagsJson.isEmpty && cycleLogsJson.isEmpty && symptomLogsJson.isEmpty) {
      return; 
    }

    final Map<String, CustomTagDto> tagsToPut = Map.fromEntries(
      tagsJson.map((tagMap) => _createTagEntry(Map<String, dynamic>.from(tagMap)))
    );

    final Map<String, CycleLogDto> cyclesToPut = Map.fromEntries(
      cycleLogsJson.map((logMap) => _createCycleEntry(Map<String, dynamic>.from(logMap)))
    );

    final Map<String, SymptomLogDto> symptomsToPut = Map.fromEntries(
      symptomLogsJson.map((logMap) => _createSymptomEntry(Map<String, dynamic>.from(logMap)))
    );

    await _cycleDataSource.clear();
    await _symptomDataSource.clear();
    await _tagDataSource.clear();

    await _tagDataSource.putAll(tagsToPut);
    await _cycleDataSource.putAll(cyclesToPut);
    await _symptomDataSource.putAll(symptomsToPut);

    await _dbManager.updateLastModified();
  }

  /// Persists merged record maps into local storage without wiping.
  Future<void> persistMergedMap(Map<String, dynamic> mergedData) async {
    final cycleLogs = (mergedData['cycleLogs'] as List)
        .map((m) => ModelMapper.cycleLogFromMap(Map<String, dynamic>.from(m)))
        .toList();
    final symptomLogs = (mergedData['symptomLogs'] as List)
        .map((m) => ModelMapper.symptomLogFromMap(Map<String, dynamic>.from(m)))
        .toList();
    final customTags = (mergedData['customTags'] as List)
        .map((m) => ModelMapper.customTagFromMap(Map<String, dynamic>.from(m)))
        .toList();

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

  MapEntry<String, CustomTagDto> _createTagEntry(Map<String, dynamic> map) {
    final domain = ModelMapper.customTagFromMap(map);
    return MapEntry(domain.id, CustomTagDto.fromDomain(domain));
  }

  MapEntry<String, CycleLogDto> _createCycleEntry(Map<String, dynamic> map) {
    final domain = ModelMapper.cycleLogFromMap(map);
    return MapEntry(domain.id, CycleLogDto.fromDomain(domain));
  }

  MapEntry<String, SymptomLogDto> _createSymptomEntry(Map<String, dynamic> map) {
    final domain = ModelMapper.symptomLogFromMap(map);
    return MapEntry(domain.id, SymptomLogDto.fromDomain(domain));
  }
}
