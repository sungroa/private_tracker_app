import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/core/registry/hive_registry.dart';
import 'package:private_tracker_app/data/repositories/sync_metadata_repository_impl.dart';
import 'package:private_tracker_app/data/storage/local_database_manager.dart';

class MockLocalDatabaseManager extends Mock implements LocalDatabaseManager {}
class MockStringBox extends Mock implements Box<String> {}

void main() {
  late SyncMetadataRepositoryImpl repository;
  late MockLocalDatabaseManager mockDbManager;
  late MockStringBox mockBox;

  setUp(() {
    mockDbManager = MockLocalDatabaseManager();
    mockBox = MockStringBox();
    repository = SyncMetadataRepositoryImpl(mockDbManager);

    when(() => mockDbManager.getBox<String>(HiveRegistry.metaBox)).thenReturn(mockBox);
  });

  group('SyncMetadataRepositoryImpl Tests', () {
    test('getLastSyncChecksum returns value from box', () async {
      when(() => mockBox.get(HiveRegistry.lastSyncChecksumKey)).thenReturn('sum123');
      final result = await repository.getLastSyncChecksum();
      expect(result, 'sum123');
    });

    test('setLastSyncChecksum puts value in box', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      await repository.setLastSyncChecksum('sum456');
      verify(() => mockBox.put(HiveRegistry.lastSyncChecksumKey, 'sum456')).called(1);
    });

    test('setLastSyncChecksum deletes if null', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});
      await repository.setLastSyncChecksum(null);
      verify(() => mockBox.delete(HiveRegistry.lastSyncChecksumKey)).called(1);
    });

    test('getLastLocalModified returns value from box', () async {
      when(() => mockBox.get(HiveRegistry.lastLocalModifiedKey)).thenReturn('2026-05-15');
      final result = await repository.getLastLocalModified();
      expect(result, '2026-05-15');
    });

    test('clearLocalModifiedFlag deletes from box', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});
      await repository.clearLocalModifiedFlag();
      verify(() => mockBox.delete(HiveRegistry.lastLocalModifiedKey)).called(1);
    });

    test('getRecoverySalt returns value from box', () async {
      when(() => mockBox.get(HiveRegistry.recoverySaltKey)).thenReturn('salt123');
      final result = await repository.getRecoverySalt();
      expect(result, 'salt123');
    });

    test('setRecoverySalt puts value in box', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      await repository.setRecoverySalt('salt456');
      verify(() => mockBox.put(HiveRegistry.recoverySaltKey, 'salt456')).called(1);
    });
  });
}
