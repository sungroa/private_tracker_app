import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/usecases/sync_data_use_case.dart';
import 'package:private_tracker_app/domain/services/cloud_sync_interface.dart';
import 'package:private_tracker_app/domain/repositories/data_source_repository.dart';
import 'package:private_tracker_app/domain/repositories/sync_metadata_repository.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/data/storage/model_mapper.dart';

class MockCloudSync extends Mock implements CloudSyncInterface {}
class MockDataSourceRepository extends Mock implements IDataSourceRepository {}
class MockSyncMetadataRepository extends Mock implements ISyncMetadataRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  late SyncDataUseCase useCase;
  late MockCloudSync mockCloudSync;
  late MockDataSourceRepository mockDataSource;
  late MockSyncMetadataRepository mockMetadata;

  setUp(() {
    mockCloudSync = MockCloudSync();
    mockDataSource = MockDataSourceRepository();
    mockMetadata = MockSyncMetadataRepository();

    useCase = SyncDataUseCase(
      cloudSync: mockCloudSync,
      dataSource: mockDataSource,
      metadata: mockMetadata,
      keyProvider: () async => [1, 2, 3],
    );

    when(() => mockCloudSync.authenticate()).thenAnswer((_) async {});
  });

  group('SyncDataUseCase Tests', () {
    test('execute should perform initial upload if cloud is empty', () async {
      when(() => mockCloudSync.fetchLatestCloudChecksum()).thenAnswer((_) async => null);
      when(() => mockMetadata.getLastSyncChecksum()).thenAnswer((_) async => null);
      when(() => mockMetadata.getLastLocalModified()).thenAnswer((_) async => 'some_date');
      
      when(() => mockDataSource.exportCloudBackup(any())).thenAnswer((_) async => Uint8List.fromList([4, 5, 6]));
      when(() => mockCloudSync.uploadEncryptedBackup(any(), any())).thenAnswer((_) async {});
      when(() => mockMetadata.setLastSyncChecksum(any())).thenAnswer((_) async {});
      when(() => mockMetadata.clearLocalModifiedFlag()).thenAnswer((_) async {});

      final result = await useCase.execute();

      expect(result, isFalse);
      verify(() => mockCloudSync.uploadEncryptedBackup(any(), any())).called(1);
    });

    test('execute should skip if checksums match and no local modifications', () async {
      when(() => mockCloudSync.fetchLatestCloudChecksum()).thenAnswer((_) async => 'checksum123');
      when(() => mockMetadata.getLastSyncChecksum()).thenAnswer((_) async => 'checksum123');
      when(() => mockMetadata.getLastLocalModified()).thenAnswer((_) async => null);

      final result = await useCase.execute();

      expect(result, isFalse);
      verifyNever(() => mockCloudSync.downloadEncryptedBackup());
    });

    test('execute should merge and upload if cloud is newer', () async {
      final now = DateTime.now();
      final localLog = CycleLog(id: '1', startDate: now, updatedAt: now);
      final cloudLog = CycleLog(id: '1', startDate: now, updatedAt: now.add(const Duration(minutes: 5)));

      when(() => mockCloudSync.fetchLatestCloudChecksum()).thenAnswer((_) async => '787c798e39a5bc1910355bae6d0cd87a36b2e10fd0202a83e3bb6b005da83472'); // Correct sha256 of [4,5,6]
      when(() => mockMetadata.getLastSyncChecksum()).thenAnswer((_) async => 'local_old');
      when(() => mockMetadata.getLastLocalModified()).thenAnswer((_) async => null);

      when(() => mockCloudSync.downloadEncryptedBackup()).thenAnswer((_) async => Uint8List.fromList([4, 5, 6]));
      
      when(() => mockDataSource.parseCloudBackup(any(), any())).thenAnswer((_) async => {
        'cycleLogs': [ModelMapper.cycleLogToMap(cloudLog)],
        'symptomLogs': [],
        'customTags': [],
      });

      when(() => mockDataSource.getAllDataAsMap()).thenAnswer((_) async => {
        'cycleLogs': [ModelMapper.cycleLogToMap(localLog)],
        'symptomLogs': [],
        'customTags': [],
      });

      when(() => mockDataSource.persistMergedMap(any())).thenAnswer((_) async {});
      
      when(() => mockDataSource.exportCloudBackup(any())).thenAnswer((_) async => Uint8List.fromList([7, 8, 9]));
      when(() => mockCloudSync.uploadEncryptedBackup(any(), any())).thenAnswer((_) async {});
      when(() => mockMetadata.setLastSyncChecksum(any())).thenAnswer((_) async {});
      when(() => mockMetadata.clearLocalModifiedFlag()).thenAnswer((_) async {});

      final result = await useCase.execute();

      expect(result, isTrue);
      
      final captured = verify(() => mockDataSource.persistMergedMap(captureAny())).captured;

      final Map<String, dynamic> mergedMap = captured.first;
      final List<dynamic> mergedCycles = mergedMap['cycleLogs'];
      expect(mergedCycles.first['updatedAt'], cloudLog.updatedAt.toUtc().toIso8601String());
    });
  });
}
