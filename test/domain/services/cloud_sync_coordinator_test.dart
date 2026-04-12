import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/services/cloud_sync_coordinator.dart';
import 'package:private_tracker_app/domain/services/cloud_sync_interface.dart';
import 'package:private_tracker_app/domain/usecases/sync_data_use_case.dart';

class MockCloudSyncInterface extends Mock implements CloudSyncInterface {}
class MockSyncUseCase extends Mock implements SyncDataUseCase {}

void main() {
  late CloudSyncCoordinator coordinator;
  late MockCloudSyncInterface mockCloudSync;
  late MockSyncUseCase mockSyncUseCase;

  setUpAll(() {
    registerFallbackValue(File(''));
  });

  setUp(() {
    mockCloudSync = MockCloudSyncInterface();
    mockSyncUseCase = MockSyncUseCase();

    coordinator = CloudSyncCoordinator(
      cloudSync: mockCloudSync,
      syncUseCase: mockSyncUseCase,
    );
  });

  group('CloudSyncCoordinator', () {
    test('sync() delegates to SyncDataUseCase', () async {
      when(() => mockSyncUseCase.execute()).thenAnswer((_) async => true);

      await coordinator.sync();

      verify(() => mockSyncUseCase.execute()).called(1);
    });
  });
}
