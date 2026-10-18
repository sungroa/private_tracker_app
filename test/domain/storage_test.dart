import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:private_tracker_app/data/storage/backup_orchestrator.dart';
import 'package:private_tracker_app/data/storage/backup_restore_service.dart';
import 'package:private_tracker_app/data/storage/data_export_service.dart';
import 'package:private_tracker_app/data/storage/data_sources/cycle_data_source.dart';
import 'package:private_tracker_app/data/storage/data_sources/data_seeding_service.dart';
import 'package:private_tracker_app/data/storage/data_sources/symptom_data_source.dart';
import 'package:private_tracker_app/data/storage/data_sources/tag_data_source.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/data/storage/local_database_manager.dart';
import 'package:private_tracker_app/data/storage/secure_key_storage.dart';

import '../helpers/test_model_factory.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {}

void main() {
  group('EncryptedStorageService & BackupOrchestrator Tests', () {
    late Directory tempDir;
    late MockFlutterSecureStorage mockStorage;
    late EncryptedStorageService storageService;
    late BackupOrchestrator backupOrchestrator;
    late CycleDataSource cycleDataSource;
    late SymptomDataSource symptomDataSource;
    late TagDataSource tagDataSource;
    late LocalDatabaseManager dbManager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test');
      Hive.init(tempDir.path);

      mockStorage = MockFlutterSecureStorage();
      final mockPathProvider = MockPathProviderPlatform();
      PathProviderPlatform.instance = mockPathProvider;
      when(() => mockPathProvider.getTemporaryPath()).thenAnswer((_) async => tempDir.path);
      when(
        () => mockPathProvider.getApplicationDocumentsPath(),
      ).thenAnswer((_) async => tempDir.path);

      dbManager = LocalDatabaseManager();
      cycleDataSource = CycleDataSource(dbManager);
      symptomDataSource = SymptomDataSource(dbManager);
      tagDataSource = TagDataSource(dbManager);

      storageService = EncryptedStorageService(
        keyStorage: SecureKeyStorage(mockStorage),
        dbManager: dbManager,
        exportService: DataExportService(),
        seedingService: DataSeedingService(),
        cycleDataSource: cycleDataSource,
        symptomDataSource: symptomDataSource,
        tagDataSource: tagDataSource,
      );

      backupOrchestrator = BackupOrchestrator(
        backupService: BackupRestoreService(),
        dbManager: dbManager,
        cycleDataSource: cycleDataSource,
        symptomDataSource: symptomDataSource,
        tagDataSource: tagDataSource,
      );

      final key = Hive.generateSecureKey();
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => base64UrlEncode(key));
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async => {});

      await storageService.initialize(basePath: tempDir.path);
    });

    tearDown(() async {
      await dbManager.close();
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saveSymptomLog should save with date-based key', () async {
      final date = DateTime(2026, 3, 28);
      final log = TestModelFactory.createSymptomLog(
        date: date,
        symptoms: const ['Cramps', 'Headache'],
        moodRating: 4,
      );

      await symptomDataSource.saveSymptomLog(log);

      final savedLogs = await symptomDataSource.getSymptomLogsForMonth(date);
      expect(savedLogs.length, 1);
      expect(savedLogs.first.symptoms, contains('Cramps'));
    });

    test('getSymptomLogsForMonth should filter correctly', () async {
      await symptomDataSource.saveSymptomLog(
        TestModelFactory.createSymptomLog(date: DateTime(2026, 3, 28), symptoms: const ['Cramps']),
      );
      await symptomDataSource.saveSymptomLog(
        TestModelFactory.createSymptomLog(date: DateTime(2026, 4, 1), symptoms: const ['Bloating']),
      );

      final marchLogs = await symptomDataSource.getSymptomLogsForMonth(DateTime(2026, 3, 1));
      expect(marchLogs.length, 1);
      expect(marchLogs.first.symptoms, contains('Cramps'));
    });

    test('saveCycleLog and getCycleLogs should work', () async {
      final log1 = TestModelFactory.createCycleLog(startDate: DateTime(2026, 2, 1));
      final log2 = TestModelFactory.createCycleLog(startDate: DateTime(2026, 3, 1));

      await cycleDataSource.saveCycleLog(log1);
      await cycleDataSource.saveCycleLog(log2);

      final allLogs = await cycleDataSource.getCycleLogs();
      expect(allLogs.length, 2);
      expect(allLogs.first.startDate, DateTime(2026, 3, 1));
    });

    test('exportDataToCsv should format CSV string correctly', () async {
      await cycleDataSource.clear();
      await symptomDataSource.clear();

      await cycleDataSource.saveCycleLog(
        TestModelFactory.createCycleLog(startDate: DateTime(2026, 3, 1), notes: 'Cycle note'),
      );
      await symptomDataSource.saveSymptomLog(
        TestModelFactory.createSymptomLog(
          date: DateTime(2026, 3, 5),
          symptoms: const ['Cramps', 'Fatigue'],
          moodRating: 3,
          notes: 'Symptom note',
        ),
      );

      final csvString = await storageService.exportDataToCsv();

      expect(
        csvString,
        contains('Date,Type,End Date,Symptoms,Mood,Flow,BBT,Fluid,LH Test,Notes,Last Updated,ID'),
      );
      expect(csvString, contains('2026-03-01,Cycle,,,,3/5,,,,Cycle note'));
      expect(csvString, contains('2026-03-05,Symptom,,Cramps; Fatigue,3,,,,,Symptom note'));
    });

    test('saveTag and deleteTag should work', () async {
      await tagDataSource.clear();

      final tag = TestModelFactory.createTag(name: 'New Symptom');
      await tagDataSource.saveTag(tag);
      expect((await tagDataSource.getCustomTags()).length, 1);

      await tagDataSource.delete(tag.id);
      expect((await tagDataSource.getCustomTags()).length, 0);
    });

    test('Encrypted backup and restore should preserve all data', () async {
      await cycleDataSource.clear();
      await symptomDataSource.clear();
      await tagDataSource.clear();

      await cycleDataSource.saveCycleLog(TestModelFactory.createCycleLog(notes: 'Backup test'));
      await symptomDataSource.saveSymptomLog(
        TestModelFactory.createSymptomLog(symptoms: const ['Cramps'], moodRating: 5),
      );
      await tagDataSource.saveTag(TestModelFactory.createTag(name: 'Backup Tag'));

      // 2. Export
      const password = 'test-password-123';
      final backupFile = await backupOrchestrator.exportEncryptedBackup(password);
      expect(await backupFile.exists(), isTrue);

      // 3. Clear local state
      await cycleDataSource.clear();
      await symptomDataSource.clear();
      await tagDataSource.clear();
      expect(await cycleDataSource.getCycleLogs(), isEmpty);

      // 4. Restore
      await backupOrchestrator.importEncryptedBackup(backupFile, password);

      // 5. Verify
      final cycles = await cycleDataSource.getCycleLogs();
      final symptoms = await symptomDataSource.getSymptomLogs();
      final tags = await tagDataSource.getCustomTags();

      expect(cycles.length, 1);
      expect(cycles.first.notes, 'Backup test');
      expect(symptoms.length, 1);
      expect(symptoms.first.moodRating, 5);
      expect(tags.any((t) => t.name == 'Backup Tag'), isTrue);

      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    });
  });
}
