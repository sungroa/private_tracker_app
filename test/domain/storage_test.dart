import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/models/custom_tag.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('EncryptedStorageService Tests', () {
    late Directory tempDir;
    late MockFlutterSecureStorage mockStorage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test');
      Hive.init(tempDir.path);
      
      mockStorage = MockFlutterSecureStorage();
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

    test('saveCycleLog and getCycleLogs should work', () async {
      final log1 = CycleLog(startDate: DateTime(2026, 2, 1));
      final log2 = CycleLog(startDate: DateTime(2026, 3, 1));

      await EncryptedStorageService.instance.saveCycleLog(log1);
      await EncryptedStorageService.instance.saveCycleLog(log2);

      final allLogs = EncryptedStorageService.instance.getCycleLogs();
      expect(allLogs.length, 2);
      expect(allLogs.first.startDate, DateTime(2026, 3, 1)); // Sorted newest first
    });

    test('exportDataToCsv should format CSV string correctly', () async {
      await Hive.box<CycleLog>(EncryptedStorageService.cycleLogBox).clear();
      await Hive.box<SymptomLog>(EncryptedStorageService.symptomLogBox).clear();

      await EncryptedStorageService.instance.saveCycleLog(CycleLog(startDate: DateTime(2026, 3, 1), notes: 'Cycle note'));
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
  });
}
