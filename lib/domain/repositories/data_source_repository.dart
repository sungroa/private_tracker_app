import 'dart:typed_data';
import '../models/cycle_log.dart';
import '../models/symptom_log.dart';
import '../models/custom_tag.dart';

/// Domain interface for bulk data operations required by the synchronization logic.
/// 
/// This repository provides an abstraction over the `EncryptedStorageService`
/// to allow the domain layer to orchestrate sync cycles without direct knowledge
/// of Hive, AES initialization, or specific data source implementations.
abstract class IDataSourceRepository {
  /// Aggregates all currently stored user data into a serializable Map.
  /// 
  /// The resulting Map structure should contain:
  /// - 'cycleLogs': List of Map
  /// - 'symptomLogs': List of Map
  /// - 'customTags': List of Map
  Map<String, dynamic> getAllDataAsMap();

  /// Persists merged domain objects into local storage.
  /// 
  /// This operation should be idempotent and use Last-Write-Wins logic (LWW)
  /// to update existing records or insert new ones.
  Future<void> persistMergedData({
    required List<CycleLog> cycleLogs,
    required List<SymptomLog> symptomLogs,
    required List<CustomTag> customTags,
  });

  /// Hydrates and persists merged map data.
  Future<void> persistMergedMap(Map<String, dynamic> mergedData);

  /// Exports an encrypted cloud-compatible backup.
  /// 
  /// [cloudKey] The persistent encryption key derived from Secure Storage.
  /// Returns the raw binary payload of the encrypted backup.
  Future<Uint8List> exportCloudBackup(List<int> cloudKey);

  /// Decrypts and parses a cloud backup payload into a Map.
  /// 
  /// [payload] The raw binary payload from cloud storage.
  /// [cloudKey] The persistent encryption key.
  Future<Map<String, dynamic>> parseCloudBackup(Uint8List payload, List<int> cloudKey);
}
