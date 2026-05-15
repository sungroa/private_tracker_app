import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/data/storage/backup_orchestrator.dart';
import 'package:private_tracker_app/data/storage/backup_restore_service.dart';
import 'package:private_tracker_app/data/storage/data_sources/cycle_data_source.dart';
import 'package:private_tracker_app/data/storage/data_sources/symptom_data_source.dart';
import 'package:private_tracker_app/data/storage/data_sources/tag_data_source.dart';
import 'package:private_tracker_app/data/storage/local_database_manager.dart';

class MockBackupRestoreService extends Mock implements BackupRestoreService {}
class MockLocalDatabaseManager extends Mock implements LocalDatabaseManager {}
class MockCycleDataSource extends Mock implements CycleDataSource {}
class MockSymptomDataSource extends Mock implements SymptomDataSource {}
class MockTagDataSource extends Mock implements TagDataSource {}

void main() {
  late BackupOrchestrator orchestrator;
  late MockBackupRestoreService mockBackupService;
  late MockLocalDatabaseManager mockDbManager;
  late MockCycleDataSource mockCycleDS;
  late MockSymptomDataSource mockSymptomDS;
  late MockTagDataSource mockTagDS;

  setUp(() {
    mockBackupService = MockBackupRestoreService();
    mockDbManager = MockLocalDatabaseManager();
    mockCycleDS = MockCycleDataSource();
    mockSymptomDS = MockSymptomDataSource();
    mockTagDS = MockTagDataSource();

    orchestrator = BackupOrchestrator(
      backupService: mockBackupService,
      dbManager: mockDbManager,
      cycleDataSource: mockCycleDS,
      symptomDataSource: mockSymptomDS,
      tagDataSource: mockTagDS,
    );
  });

  group('BackupOrchestrator Tests', () {
    test('exportCloudBackup should fetch data from all sources and call backup service', () async {
      final key = [1, 2, 3];
      when(() => mockCycleDS.getCycleLogs()).thenAnswer((_) async => []);
      when(() => mockSymptomDS.getSymptomLogs()).thenAnswer((_) async => []);
      when(() => mockTagDS.getCustomTags()).thenAnswer((_) async => []);
      when(() => mockBackupService.exportBackupWithKey(
            encryptionKey: any(named: 'encryptionKey'),
            cycleEvents: any(named: 'cycleEvents'),
            symptomLogs: any(named: 'symptomLogs'),
            customTags: any(named: 'customTags'),
          )).thenAnswer((_) async => Uint8List(0));

      await orchestrator.exportCloudBackup(key);

      verify(() => mockCycleDS.getCycleLogs()).called(1);
      verify(() => mockSymptomDS.getSymptomLogs()).called(1);
      verify(() => mockTagDS.getCustomTags()).called(1);
      verify(() => mockBackupService.exportBackupWithKey(
            encryptionKey: key,
            cycleEvents: any(named: 'cycleEvents'),
            symptomLogs: any(named: 'symptomLogs'),
            customTags: any(named: 'customTags'),
          )).called(1);
    });

    test('restoreData should be atomic: clear then putAll', () async {
      final data = {
        'cycleLogs': [
          {'id': '1', 'startDate': '2026-03-01T00:00:00.000Z', 'updatedAt': '2026-03-01T00:00:00.000Z'}
        ],
        'symptomLogs': [],
        'customTags': [],
      };

      when(() => mockCycleDS.clear()).thenAnswer((_) async => {});
      when(() => mockSymptomDS.clear()).thenAnswer((_) async => {});
      when(() => mockTagDS.clear()).thenAnswer((_) async => {});
      when(() => mockCycleDS.putAll(any())).thenAnswer((_) async => {});
      when(() => mockSymptomDS.putAll(any())).thenAnswer((_) async => {});
      when(() => mockTagDS.putAll(any())).thenAnswer((_) async => {});
      when(() => mockDbManager.updateLastModified()).thenAnswer((_) async => {});

      await orchestrator.restoreData(data);

      verify(() => mockCycleDS.clear()).called(1);
      verify(() => mockSymptomDS.clear()).called(1);
      verify(() => mockTagDS.clear()).called(1);
      verify(() => mockCycleDS.putAll(any())).called(1);
      verify(() => mockDbManager.updateLastModified()).called(1);
    });

    test('restoreData with empty data should return early', () async {
      await orchestrator.restoreData({});
      verifyNever(() => mockCycleDS.clear());
    });

    test('persistMergedMap should not clear data', () async {
      final data = {
        'cycleLogs': [
          {'id': '1', 'startDate': '2026-03-01T00:00:00.000Z', 'updatedAt': '2026-03-01T00:00:00.000Z'}
        ],
        'symptomLogs': [],
        'customTags': [],
      };

      when(() => mockCycleDS.putAll(any())).thenAnswer((_) async => {});
      when(() => mockSymptomDS.putAll(any())).thenAnswer((_) async => {});
      when(() => mockTagDS.putAll(any())).thenAnswer((_) async => {});
      when(() => mockDbManager.updateLastModified()).thenAnswer((_) async => {});

      await orchestrator.persistMergedMap(data);

      verifyNever(() => mockCycleDS.clear());
      verify(() => mockCycleDS.putAll(any())).called(1);
      verify(() => mockDbManager.updateLastModified()).called(1);
    });
  });
}
