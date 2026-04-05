import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/data/storage/secure_key_storage.dart';
import 'package:private_tracker_app/data/storage/local_database_manager.dart';
import 'package:private_tracker_app/data/storage/backup_restore_service.dart';
import 'package:private_tracker_app/data/storage/data_export_service.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';
import 'package:private_tracker_app/data/storage/hive_dtos.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockPathProviderPlatform extends Mock with MockPlatformInterfaceMixin implements PathProviderPlatform {}

void main() {
  group('EncryptedStorageService Tests', () {
    late Directory tempDir;
    late MockFlutterSecureStorage mockStorage;
    late EncryptedStorageService storageService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test');
      Hive.init(tempDir.path);
      
      mockStorage = MockFlutterSecureStorage();
      final mockPathProvider = MockPathProviderPlatform();
      PathProviderPlatform.instance = mockPathProvider;
      when(() => mockPathProvider.getTemporaryPath()).thenAnswer((_) async => tempDir.path);
      when(() => mockPathProvider.getApplicationDocumentsPath()).thenAnswer((_) async => tempDir.path);

      storageService = EncryptedStorageService(
        keyStorage: SecureKeyStorage(mockStorage),
        dbManager: LocalDatabaseManager(),
        backupService: BackupRestoreService(),
        exportService: DataExportService(),
      );

      // Mock encryption key logic
      final key = Hive.generateSecureKey();
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => base64UrlEncode(key));
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async => {});

      await storageService.initialize(basePath: tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saveSymptomLog should save with date-based key', () async {
      final date = DateTime(2026, 3, 28);
      final log = SymptomLog(
        id: 'test-id',
        date: date,
        symptoms: ['Cramps', 'Headache'],
        moodRating: 4,
      );

      await storageService.saveSymptomLog(log);

      final savedLogs = storageService.getSymptomLogsForMonth(date);
      expect(savedLogs.length, 1);
      expect(savedLogs.first.symptoms, contains('Cramps'));
    });

    test('getSymptomLogsForMonth should filter correctly', () async {
      await storageService.saveSymptomLog(SymptomLog(
        id: 'id1',
        date: DateTime(2026, 3, 28),
        symptoms: ['Cramps'],
        moodRating: 3,
      ));
      await storageService.saveSymptomLog(SymptomLog(
        id: 'id2',
        date: DateTime(2026, 4, 1),
        symptoms: ['Bloating'],
        moodRating: 2,
      ));

      final marchLogs = storageService.getSymptomLogsForMonth(DateTime(2026, 3, 1));
      expect(marchLogs.length, 1);
      expect(marchLogs.first.symptoms, contains('Cramps'));
    });

    test('saveCycleEvent and getCycleEvents should work', () async {
      final log1 = CycleEvent(id: 'c1', startDate: DateTime(2026, 2, 1));
      final log2 = CycleEvent(id: 'c2', startDate: DateTime(2026, 3, 1));

      await storageService.saveCycleEvent(log1);
      await storageService.saveCycleEvent(log2);

      final allLogs = storageService.getCycleEvents();
      expect(allLogs.length, 2);
      expect(allLogs.first.startDate, DateTime(2026, 3, 1)); // Sorted newest first
    });

    test('exportDataToCsv should format CSV string correctly', () async {
      await storageService.getBox<CycleEventDto>(LocalDatabaseManager.cycleLogBox).clear();
      await storageService.getBox<SymptomLogDto>(LocalDatabaseManager.symptomLogBox).clear();

      await storageService.saveCycleEvent(CycleEvent(id: 'c1', startDate: DateTime(2026, 3, 1), notes: 'Cycle note'));
      await storageService.saveSymptomLog(SymptomLog(
        id: 's1',
        date: DateTime(2026, 3, 5),
        symptoms: ['Cramps', 'Fatigue'],
        moodRating: 3,
        notes: 'Symptom note',
      ));

      final csvString = await storageService.exportDataToCsv();
      
      expect(csvString, contains('Log Type,Start Date/Date,End Date,Symptoms,Mood Rating,BBT,Fluid,LH Test,Notes'));
      expect(csvString, contains('Cycle,2026-03-01,,,,,,,Cycle note'));
      expect(csvString, contains('Symptom,2026-03-05,,Cramps; Fatigue,3,,,,Symptom note'));
    });

    test('addCustomTag and deleteCustomTag should work', () async {
      final box = storageService.getBox<CustomTagDto>(LocalDatabaseManager.customTagBox);
      await box.clear();

      await storageService.addCustomTag('New Symptom');
      expect(box.length, 1);
      expect(box.values.first.name, 'New Symptom');

      await storageService.addCustomTag('NEW SYMPTOM');
      expect(box.length, 1);

      final tag = box.values.first.sovereignty();
      await storageService.deleteCustomTag(tag);
      expect(box.length, 0);
    });

    test('Encrypted backup and restore should preserve all data', () async {
      // 1. Prepare data
      await storageService.getBox<CycleEventDto>(LocalDatabaseManager.cycleLogBox).clear();
      await storageService.getBox<SymptomLogDto>(LocalDatabaseManager.symptomLogBox).clear();
      await storageService.getBox<CustomTagDto>(LocalDatabaseManager.customTagBox).clear();

      await storageService.saveCycleEvent(CycleEvent(id: 'c1', startDate: DateTime(2026, 3, 1), notes: 'Backup test'));
      await storageService.saveSymptomLog(SymptomLog(
        id: 's1',
        date: DateTime(2026, 3, 5),
        symptoms: ['Cramps'],
        moodRating: 5,
      ));
      await storageService.addCustomTag('Backup Tag');

      // 2. Export
      final password = 'test-password-123';
      final backupFile = await storageService.exportEncryptedBackup(password);
      expect(await backupFile.exists(), isTrue);

      // 3. Clear local state
      await storageService.getBox<CycleEventDto>(LocalDatabaseManager.cycleLogBox).clear();
      await storageService.getBox<SymptomLogDto>(LocalDatabaseManager.symptomLogBox).clear();
      await storageService.getBox<CustomTagDto>(LocalDatabaseManager.customTagBox).clear();
      expect(storageService.getCycleEvents(), isEmpty);

      // 4. Restore
      await storageService.importEncryptedBackup(backupFile, password);

      // 5. Verify
      final cycles = storageService.getCycleEvents();
      final symptoms = storageService.getSymptomLogs();
      final tags = storageService.getCustomTags();

      expect(cycles.length, 1);
      expect(cycles.first.notes, 'Backup test');
      expect(symptoms.length, 1);
      expect(symptoms.first.moodRating, 5);
      expect(tags.any((t) => t.name == 'Backup Tag'), isTrue);

      // Clean up
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    });

    test('Restore should fail with wrong password', () async {
      final password = 'right-password';
      final backupFile = await storageService.exportEncryptedBackup(password);
      
      expect(
        () => storageService.importEncryptedBackup(backupFile, 'wrong-password'),
        throwsException,
      );

      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    });
  });
}
