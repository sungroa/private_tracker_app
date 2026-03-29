import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/models/custom_tag.dart';


void main() {
  group('EncryptedStorageService Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test');
      Hive.init(tempDir.path);
      
      // We can't easily test the encrypted secure storage in a unit test without mocking 
      // FlutterSecureStorage. For now, we'll manually register adapters and open boxes 
      // without encryption for logic verification.
      
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CycleLogAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SymptomLogAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CustomTagAdapter());

      await Hive.openBox<CycleLog>(EncryptedStorageService.cycleLogBox);
      await Hive.openBox<SymptomLog>(EncryptedStorageService.symptomLogBox);
      await Hive.openBox<CustomTag>(EncryptedStorageService.customTagBox);

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

      await EncryptedStorageService.saveSymptomLog(log);

      final savedLogs = EncryptedStorageService.getSymptomLogsForMonth(date);
      expect(savedLogs.length, 1);
      expect(savedLogs.first.symptoms, contains('Cramps'));
    });

    test('getSymptomLogsForMonth should filter correctly', () async {
      await EncryptedStorageService.saveSymptomLog(SymptomLog(
        date: DateTime(2026, 3, 28),
        symptoms: ['Cramps'],
        moodRating: 3,
      ));
      await EncryptedStorageService.saveSymptomLog(SymptomLog(
        date: DateTime(2026, 4, 1),
        symptoms: ['Bloating'],
        moodRating: 2,
      ));

      final marchLogs = EncryptedStorageService.getSymptomLogsForMonth(DateTime(2026, 3, 1));
      expect(marchLogs.length, 1);
      expect(marchLogs.first.symptoms, contains('Cramps'));
    });

    test('saveCycleLog and getCycleLogs should work', () async {
      final log1 = CycleLog(startDate: DateTime(2026, 2, 1));
      final log2 = CycleLog(startDate: DateTime(2026, 3, 1));

      await EncryptedStorageService.saveCycleLog(log1);
      await EncryptedStorageService.saveCycleLog(log2);

      final allLogs = EncryptedStorageService.getCycleLogs();
      expect(allLogs.length, 2);
      expect(allLogs.first.startDate, DateTime(2026, 3, 1)); // Sorted newest first
    });

    test('exportDataToCsv should format CSV string correctly', () async {
      // Clear before test
      await Hive.box<CycleLog>(EncryptedStorageService.cycleLogBox).clear();
      await Hive.box<SymptomLog>(EncryptedStorageService.symptomLogBox).clear();

      await EncryptedStorageService.saveCycleLog(CycleLog(startDate: DateTime(2026, 3, 1), notes: 'Cycle note'));
      await EncryptedStorageService.saveSymptomLog(SymptomLog(
        date: DateTime(2026, 3, 5),
        symptoms: ['Cramps', 'Fatigue'],
        moodRating: 3,
        notes: 'Symptom note',
      ));

      final csvString = await EncryptedStorageService.exportDataToCsv();
      
      expect(csvString, contains('Log Type,Start Date/Date,End Date,Symptoms,Mood Rating,BBT,Fluid,LH Test,Notes'));
      expect(csvString, contains('Cycle,2026-03-01,,,,,,,Cycle note'));
      expect(csvString, contains('Symptom,2026-03-05,,Cramps; Fatigue,3,,,,Symptom note'));
    });

    test('addCustomTag and deleteCustomTag should work', () async {
      final box = EncryptedStorageService.getCustomTagsBox();
      await box.clear();

      await EncryptedStorageService.addCustomTag('New Symptom');
      expect(box.length, 1);
      expect(box.values.first.name, 'New Symptom');

      // Duplicate check
      await EncryptedStorageService.addCustomTag('NEW SYMPTOM'); // Case insensitive duplicate
      expect(box.length, 1);

      final tag = box.values.first;
      await EncryptedStorageService.deleteCustomTag(tag);
      expect(box.length, 0);
    });
  });
}
