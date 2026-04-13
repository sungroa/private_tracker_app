import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/presentation/providers/cloud_sync_provider.dart';
import 'package:private_tracker_app/domain/usecases/sync_data_use_case.dart';
import 'package:private_tracker_app/core/services/preferences_service.dart';

class MockSyncDataUseCase extends Mock implements SyncDataUseCase {}
class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late CloudSyncProvider provider;
  late MockSyncDataUseCase mockSyncUseCase;
  late MockPreferencesService mockPrefs;

  setUp(() {
    mockSyncUseCase = MockSyncDataUseCase();
    mockPrefs = MockPreferencesService();
    provider = CloudSyncProvider(
      syncUseCase: mockSyncUseCase,
      prefs: mockPrefs,
    );
  });

  group('CloudSyncProvider Tests', () {
    test('Initial state is not syncing and not initialized', () {
      expect(provider.isSyncing, false);
      expect(provider.isInitialized, false);
      expect(provider.isCloudEnabled, false);
    });

    test('init() loads state from preferences', () async {
      when(() => mockPrefs.isCloudSyncEnabled()).thenAnswer((_) async => true);
      when(() => mockPrefs.getLastSyncTime()).thenAnswer((_) async => DateTime(2023, 1, 1));

      await provider.init();

      expect(provider.isInitialized, true);
      expect(provider.isGoogleDriveEnabled, true);
      expect(provider.lastSyncTime, DateTime(2023, 1, 1));
      expect(provider.isCloudEnabled, true);
    });

    test('sync() executes use case and updates lastSyncTime on success', () async {
      when(() => mockPrefs.isCloudSyncEnabled()).thenAnswer((_) async => true);
      when(() => mockPrefs.getLastSyncTime()).thenAnswer((_) async => null);
      when(() => mockPrefs.setLastSyncTime(any())).thenAnswer((_) async => {});
      when(() => mockSyncUseCase.execute()).thenAnswer((_) async => true);

      await provider.init();
      await provider.sync();

      expect(provider.isSyncing, false);
      expect(provider.lastSyncTime, isNotNull);
      expect(provider.lastError, isNull);
      verify(() => mockSyncUseCase.execute()).called(1);
    });

    test('sync() captures error on failure', () async {
      when(() => mockPrefs.isCloudSyncEnabled()).thenAnswer((_) async => true);
      when(() => mockPrefs.getLastSyncTime()).thenAnswer((_) async => null);
      when(() => mockSyncUseCase.execute()).thenThrow(Exception('Sync failed'));

      await provider.init();
      await provider.sync();

      expect(provider.isSyncing, false);
      expect(provider.lastError, contains('Sync failed'));
      verify(() => mockSyncUseCase.execute()).called(1);
    });

    test('toggleGoogleDrive updates prefs and triggers sync when enabled', () async {
      when(() => mockPrefs.setCloudSyncEnabled(true)).thenAnswer((_) async => {});
      when(() => mockPrefs.isCloudSyncEnabled()).thenAnswer((_) async => true);
      when(() => mockPrefs.getLastSyncTime()).thenAnswer((_) async => null);
      when(() => mockSyncUseCase.execute()).thenAnswer((_) async => true);
      when(() => mockPrefs.setLastSyncTime(any())).thenAnswer((_) async => {});

      await provider.init();
      await provider.toggleGoogleDrive(true);

      expect(provider.isGoogleDriveEnabled, true);
      verify(() => mockPrefs.setCloudSyncEnabled(true)).called(1);
      verify(() => mockSyncUseCase.execute()).called(1);
    });
  });
}
