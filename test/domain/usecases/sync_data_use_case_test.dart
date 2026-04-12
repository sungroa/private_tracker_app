import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/usecases/sync_data_use_case.dart';
import 'package:private_tracker_app/domain/services/cloud_sync_interface.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/data/storage/secure_key_storage.dart';
import 'package:private_tracker_app/data/storage/backup_restore_service.dart';
import 'package:private_tracker_app/data/storage/local_database_manager.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:hive/hive.dart';

class MockCloudSync extends Mock implements CloudSyncInterface {}
class MockStorageService extends Mock implements EncryptedStorageService {}
class MockKeyStorage extends Mock implements SecureKeyStorage {}
class MockBackupService extends Mock implements BackupRestoreService {}
class MockDbManager extends Mock implements LocalDatabaseManager {}
class MockBox extends Mock implements Box<String> {}

void main() {
  setUpAll(() {
    registerFallbackValue(File(''));
  });

  late SyncDataUseCase useCase;
  late MockCloudSync mockCloudSync;
  late MockStorageService mockStorage;
  late MockKeyStorage mockKeyStorage;
  late MockBackupService mockBackupService;
  late MockDbManager mockDbManager;
  late MockBox mockMetaBox;

  setUp(() {
    mockCloudSync = MockCloudSync();
    mockStorage = MockStorageService();
    mockKeyStorage = MockKeyStorage();
    mockBackupService = MockBackupService();
    mockDbManager = MockDbManager();
    mockMetaBox = MockBox();

    useCase = SyncDataUseCase(
      cloudSync: mockCloudSync,
      storage: mockStorage,
      keyStorage: mockKeyStorage,
      backupService: mockBackupService,
      dbManager: mockDbManager,
    );

    when(() => mockDbManager.getBox<String>(any())).thenReturn(mockMetaBox);
    when(() => mockCloudSync.authenticate()).thenAnswer((_) async {});
  });

  group('SyncDataUseCase Tests', () {
    test('execute should perform initial upload if cloud is empty', () async {
      when(() => mockCloudSync.fetchLatestCloudChecksum()).thenAnswer((_) async => null);
      when(() => mockMetaBox.get(any())).thenReturn(null);
      when(() => mockKeyStorage.getOrCreateCloudSyncKey()).thenAnswer((_) async => [1, 2, 3]);
      when(() => mockStorage.exportCloudBackup(any())).thenAnswer((_) async => File('dummy'));
      when(() => mockCloudSync.uploadEncryptedBackup(any(), any())).thenAnswer((_) async {});
      when(() => mockMetaBox.put(any(), any())).thenAnswer((_) async {});
      when(() => mockMetaBox.delete(any())).thenAnswer((_) async {});

      final result = await useCase.execute();

      expect(result, isFalse);
      verify(() => mockCloudSync.uploadEncryptedBackup(any(), any())).called(1);
    });

    test('execute should skip if checksums match and no local modifications', () async {
      when(() => mockCloudSync.fetchLatestCloudChecksum()).thenAnswer((_) async => 'checksum123');
      when(() => mockMetaBox.get(LocalDatabaseManager.lastSyncChecksumKey)).thenReturn('checksum123');
      when(() => mockMetaBox.get(LocalDatabaseManager.lastLocalModifiedKey)).thenReturn(null);

      final result = await useCase.execute();

      expect(result, isFalse);
      verifyNever(() => mockCloudSync.downloadEncryptedBackup());
    });

    test('execute should merge and upload if cloud is newer', () async {
      final now = DateTime.now();
      final localLog = CycleLog(id: '1', startDate: now, updatedAt: now);
      final cloudLog = CycleLog(id: '1', startDate: now, updatedAt: now.add(const Duration(minutes: 5)));

      when(() => mockCloudSync.fetchLatestCloudChecksum()).thenAnswer((_) async => 'cloud_new');
      when(() => mockMetaBox.get(LocalDatabaseManager.lastSyncChecksumKey)).thenReturn('local_old');
      when(() => mockMetaBox.get(LocalDatabaseManager.lastLocalModifiedKey)).thenReturn(null);

      when(() => mockKeyStorage.getOrCreateCloudSyncKey()).thenAnswer((_) async => [1, 2, 3]);
      when(() => mockCloudSync.downloadEncryptedBackup()).thenAnswer((_) async => File('cloud'));
      
      when(() => mockBackupService.importBackupWithKey(any(), any())).thenAnswer((_) async => {
        'cycleLogs': [cloudLog.toMap()],
        'symptomLogs': [],
        'customTags': [],
      });

      when(() => mockStorage.getAllDataAsMap()).thenReturn({
        'cycleLogs': [localLog.toMap()],
        'symptomLogs': [],
        'customTags': [],
      });

      // Mocking persistMergedData and subsequent upload
      when(() => mockStorage.persistMergedData(
        cycleLogs: any(named: 'cycleLogs'),
        symptomLogs: any(named: 'symptomLogs'),
        customTags: any(named: 'customTags'),
      )).thenAnswer((_) async {});
      
      when(() => mockStorage.exportCloudBackup(any())).thenAnswer((_) async => File('merged'));
      when(() => mockCloudSync.uploadEncryptedBackup(any(), any())).thenAnswer((_) async {});
      when(() => mockMetaBox.put(any(), any())).thenAnswer((_) async {});
      when(() => mockMetaBox.delete(any())).thenAnswer((_) async {});

      final result = await useCase.execute();

      expect(result, isTrue);
      
      // Verify merge logic: cloud had newer updatedAt for the same ID
      final captured = verify(() => mockStorage.persistMergedData(
        cycleLogs: captureAny(named: 'cycleLogs'),
        symptomLogs: any(named: 'symptomLogs'),
        customTags: any(named: 'customTags'),
      )).captured;

      final List<CycleLog> mergedCycles = captured.first;
      expect(mergedCycles.first.updatedAt.isAtSameMomentAs(cloudLog.updatedAt), isTrue);
    });
  });
}
