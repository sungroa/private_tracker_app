import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/models/custom_tag.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockPathProviderPlatform extends Mock with MockPlatformInterfaceMixin implements PathProviderPlatform {}

void main() {
  group('EncryptedStorageService Tests', () {
    late Directory tempDir;
    late MockFlutterSecureStorage mockStorage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test');
      Hive.init(tempDir.path);
      
      mockStorage = MockFlutterSecureStorage();
      final mockPathProvider = MockPathProviderPlatform();
      PathProviderPlatform.instance = mockPathProvider;
      when(() => mockPathProvider.getTemporaryPath()).thenAnswer((_) async => tempDir.path);
      when(() => mockPathProvider.getApplicationDocumentsPath()).thenAnswer((_) async => tempDir.path);

      EncryptedStorageService.instance = EncryptedStorageService.test(mockStorage);

      // Mock encryption key logic
      final key = Hive.generateSecureKey();
      when(() => mockStorage.containsKey(key: any(named: 'key'))).thenAnswer((_) async => true);
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => base64UrlEncode(key));

      await EncryptedStorageService.instance.initialize(basePath: tempDir.path);
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
        date: date,
        symptoms: ['Cramps', 'Headache'],
        moodRating: 4,
      );

      await EncryptedStorageService.instance.saveSymptomLog(log);

      final savedLogs = EncryptedStorageService.instance.getSymptomLogsForMonth(date);
      expect(savedLogs.length, 1);
      expect(savedLogs.first.symptoms, contains('Cramps'));
    });

    test('getSymptomLogsForMonth should filter correctly', () async {
      await EncryptedStorageService.instance.saveSymptomLog(SymptomLog(
        date: DateTime(2026, 3, 28),
        symptoms: ['Cramps'],
        moodRating: 3,
      ));
      await EncryptedStorageService.instance.saveSymptomLog(SymptomLog(
        date: DateTime(2026, 4, 1),
        symptoms: ['Bloating'],
        moodRating: 2,
      ));

      final marchLogs = EncryptedStorageService.instance.getSymptomLogsForMonth(DateTime(2026, 3, 1));
      expect(marchLogs.length, 1);
      expect(marchLogs.first.symptoms, contains('Cramps'));
    });

    test('saveCycleEvent and getCycleEvents should work', () async {
      final log1 = CycleEvent(startDate: DateTime(2026, 2, 1));
      final log2 = CycleEvent(startDate: DateTime(2026, 3, 1));

      await EncryptedStorageService.instance.saveCycleEvent(log1);
      await EncryptedStorageService.instance.saveCycleEvent(log2);

      final allLogs = EncryptedStorageService.instance.getCycleEvents();
      expect(allLogs.length, 2);
      expect(allLogs.first.startDate, DateTime(2026, 3, 1)); // Sorted newest first
    });

    test('exportDataToCsv should format CSV string correctly', () async {
      await Hive.box<CycleEvent>(EncryptedStorageService.cycleLogBox).clear();
      await Hive.box<SymptomLog>(EncryptedStorageService.symptomLogBox).clear();

      await EncryptedStorageService.instance.saveCycleEvent(CycleEvent(startDate: DateTime(2026, 3, 1), notes: 'Cycle note'));
      await EncryptedStorageService.instance.saveSymptomLog(SymptomLog(
        date: DateTime(2026, 3, 5),
        symptoms: ['Cramps', 'Fatigue'],
        moodRating: 3,
        notes: 'Symptom note',
      ));

      final csvString = await EncryptedStorageService.instance.exportDataToCsv();
      
      expect(csvString, contains('Log Type,Start Date/Date,End Date,Symptoms,Mood Rating,BBT,Fluid,LH Test,Notes'));
      expect(csvString, contains('Cycle,2026-03-01,,,,,,,Cycle note'));
      expect(csvString, contains('Symptom,2026-03-05,,Cramps; Fatigue,3,,,,Symptom note'));
    });

    test('addCustomTag and deleteCustomTag should work', () async {
      final box = EncryptedStorageService.instance.getCustomTagsBox();
      await box.clear();

      await EncryptedStorageService.instance.addCustomTag('New Symptom');
      expect(box.length, 1);
      expect(box.values.first.name, 'New Symptom');

      await EncryptedStorageService.instance.addCustomTag('NEW SYMPTOM');
      expect(box.length, 1);

      final tag = box.values.first;
      await EncryptedStorageService.instance.deleteCustomTag(tag);
      expect(box.length, 0);
    });

    test('Encrypted backup and restore should preserve all data', () async {
      // 1. Prepare data
      await Hive.box<CycleEvent>(EncryptedStorageService.cycleLogBox).clear();
      await Hive.box<SymptomLog>(EncryptedStorageService.symptomLogBox).clear();
      await Hive.box<CustomTag>(EncryptedStorageService.customTagBox).clear();

      await EncryptedStorageService.instance.saveCycleEvent(CycleEvent(startDate: DateTime(2026, 3, 1), notes: 'Backup test'));
      await EncryptedStorageService.instance.saveSymptomLog(SymptomLog(
        date: DateTime(2026, 3, 5),
        symptoms: ['Cramps'],
        moodRating: 5,
      ));
      await EncryptedStorageService.instance.addCustomTag('Backup Tag');

      // 2. Export
      final password = 'test-password-123';
      final backupFile = await EncryptedStorageService.instance.exportEncryptedBackup(password);
      expect(await backupFile.exists(), isTrue);

      // 3. Clear local state
      await Hive.box<CycleEvent>(EncryptedStorageService.cycleLogBox).clear();
      await Hive.box<SymptomLog>(EncryptedStorageService.symptomLogBox).clear();
      await Hive.box<CustomTag>(EncryptedStorageService.customTagBox).clear();
      expect(EncryptedStorageService.instance.getCycleEvents(), isEmpty);

      // 4. Restore
      await EncryptedStorageService.instance.importEncryptedBackup(backupFile, password);

      // 5. Verify
      final cycles = EncryptedStorageService.instance.getCycleEvents();
      final symptoms = EncryptedStorageService.instance.getSymptomLogs();
      final tags = EncryptedStorageService.instance.getCustomTagsBox().values.toList();

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
      final backupFile = await EncryptedStorageService.instance.exportEncryptedBackup(password);
      
      expect(
        () => EncryptedStorageService.instance.importEncryptedBackup(backupFile, 'wrong-password'),
        throwsException,
      );

      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    });
  });
}
