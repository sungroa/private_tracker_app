import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/presentation/providers/cloud_sync_provider.dart';
import 'package:private_tracker_app/domain/usecases/sync_data_use_case.dart';
import 'package:private_tracker_app/core/services/preferences_service.dart';

import 'package:private_tracker_app/data/storage/secure_key_storage.dart';
import 'package:private_tracker_app/domain/services/cloud_sync_interface.dart';

class MockSyncDataUseCase extends Mock implements SyncDataUseCase {}
class MockPreferencesService extends Mock implements PreferencesService {}
class MockSecureKeyStorage extends Mock implements SecureKeyStorage {}
class MockCloudSyncInterface extends Mock implements CloudSyncInterface {}

void main() {
  late CloudSyncProvider provider;
  late MockSyncDataUseCase mockSyncUseCase;
  late MockPreferencesService mockPrefs;
  late MockSecureKeyStorage mockKeyStorage;
  late MockCloudSyncInterface mockCloudSync;

  setUpAll(() {
    // mocktail requires fallback values for non-nullable typed_data parameters.
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(<int>[]);
  });

  setUp(() {
    mockSyncUseCase = MockSyncDataUseCase();
    mockPrefs = MockPreferencesService();
    mockKeyStorage = MockSecureKeyStorage();
    mockCloudSync = MockCloudSyncInterface();
    
    provider = CloudSyncProvider(
      syncUseCase: mockSyncUseCase,
      prefs: mockPrefs,
      keyStorage: mockKeyStorage,
      cloudSync: mockCloudSync,
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
      when(() => mockPrefs.isRecoveryPassphraseSet()).thenAnswer((_) async => false);
      when(() => mockPrefs.getLastSyncTime()).thenAnswer((_) async => DateTime(2023, 1, 1));
      when(() => mockCloudSync.authenticate()).thenAnswer((_) async => {});
      when(() => mockCloudSync.fetchLatestCloudMetadata()).thenAnswer((_) async => null);

      await provider.init();

      expect(provider.isInitialized, true);
      expect(provider.isGoogleDriveEnabled, true);
      expect(provider.lastSyncTime, DateTime(2023, 1, 1));
      expect(provider.isCloudEnabled, true);
    });

    test('sync() executes use case and updates lastSyncTime on success', () async {
      when(() => mockPrefs.isCloudSyncEnabled()).thenAnswer((_) async => true);
      when(() => mockPrefs.isRecoveryPassphraseSet()).thenAnswer((_) async => false);
      when(() => mockPrefs.getLastSyncTime()).thenAnswer((_) async => null);
      when(() => mockPrefs.setLastSyncTime(any())).thenAnswer((_) async => {});
      when(() => mockSyncUseCase.execute()).thenAnswer((_) async => true);
      when(() => mockCloudSync.authenticate()).thenAnswer((_) async => {});
      when(() => mockCloudSync.fetchLatestCloudMetadata()).thenAnswer((_) async => null);

      await provider.init();
      await provider.sync();

      expect(provider.isSyncing, false);
      expect(provider.lastSyncTime, isNotNull);
      expect(provider.lastError, isNull);
      verify(() => mockSyncUseCase.execute()).called(1);
    });

    test('sync() captures error on failure', () async {
      when(() => mockPrefs.isCloudSyncEnabled()).thenAnswer((_) async => true);
      when(() => mockPrefs.isRecoveryPassphraseSet()).thenAnswer((_) async => false);
      when(() => mockPrefs.getLastSyncTime()).thenAnswer((_) async => null);
      when(() => mockSyncUseCase.execute()).thenThrow(Exception('Sync failed'));
      when(() => mockCloudSync.authenticate()).thenAnswer((_) async => {});
      when(() => mockCloudSync.fetchLatestCloudMetadata()).thenAnswer((_) async => null);

      await provider.init();
      await provider.sync();

      expect(provider.isSyncing, false);
      expect(provider.lastError, contains('Sync failed'));
      verify(() => mockSyncUseCase.execute()).called(1);
    });

    test('toggleGoogleDrive updates prefs and triggers sync when enabled', () async {
      when(() => mockPrefs.setCloudSyncEnabled(true)).thenAnswer((_) async => {});
      when(() => mockPrefs.isCloudSyncEnabled()).thenAnswer((_) async => true);
      when(() => mockPrefs.isRecoveryPassphraseSet()).thenAnswer((_) async => false);
      when(() => mockPrefs.getLastSyncTime()).thenAnswer((_) async => null);
      when(() => mockSyncUseCase.execute()).thenAnswer((_) async => true);
      when(() => mockPrefs.setLastSyncTime(any())).thenAnswer((_) async => {});
      when(() => mockCloudSync.authenticate()).thenAnswer((_) async => {});
      when(() => mockCloudSync.fetchLatestCloudMetadata()).thenAnswer((_) async => null);

      await provider.init();
      await provider.toggleGoogleDrive(true);

      expect(provider.isGoogleDriveEnabled, true);
      verify(() => mockPrefs.setCloudSyncEnabled(true)).called(1);
      verify(() => mockSyncUseCase.execute()).called(1);
    });

    // --- Regression: W12 guard — the root cause of the CRITICAL FAILURE spam ---
    test('toggleGoogleDrive skips sync when cloud backup requires recovery passphrase', () async {
      // Arrange: cloud has a salt (i.e., backup is password-protected)
      when(() => mockPrefs.setCloudSyncEnabled(true)).thenAnswer((_) async => {});
      when(() => mockPrefs.isCloudSyncEnabled()).thenAnswer((_) async => true);
      when(() => mockPrefs.isRecoveryPassphraseSet()).thenAnswer((_) async => false);
      when(() => mockPrefs.getLastSyncTime()).thenAnswer((_) async => null);
      when(() => mockCloudSync.authenticate()).thenAnswer((_) async => {});
      // Cloud metadata contains a recovery_salt → requiresRecoveryPrompt becomes true
      when(() => mockCloudSync.fetchLatestCloudMetadata()).thenAnswer(
        (_) async => {'recovery_salt': 'dGVzdHNhbHQ=', 'checksum': 'abc'},
      );

      await provider.init();
      await provider.toggleGoogleDrive(true);

      expect(provider.isGoogleDriveEnabled, true);
      // sync() must NOT have run — execute() must not be called
      verifyNever(() => mockSyncUseCase.execute());
    });

    // --- changePassphrase: verifies old key via cloud decrypt before rotating ---
    test('changePassphrase rotates key when old passphrase is correct', () async {
      const storedSalt = 'dGVzdHNhbHQ='; // base64url of "testsalt"
      final fakePayload = Uint8List.fromList([1, 2, 3]);

      when(() => mockPrefs.isCloudSyncEnabled()).thenAnswer((_) async => true);
      when(() => mockPrefs.isRecoveryPassphraseSet()).thenAnswer((_) async => true);
      when(() => mockPrefs.getLastSyncTime()).thenAnswer((_) async => null);
      when(() => mockPrefs.getRecoverySalt()).thenAnswer((_) async => storedSalt);
      when(() => mockPrefs.setRecoveryPassphraseSet(true)).thenAnswer((_) async => {});
      when(() => mockPrefs.setRecoverySalt(any())).thenAnswer((_) async => {});
      when(() => mockPrefs.setLastSyncTime(any())).thenAnswer((_) async => {});
      when(() => mockKeyStorage.setCloudSyncKey(any())).thenAnswer((_) async => {});
      when(() => mockCloudSync.authenticate()).thenAnswer((_) async => {});
      when(() => mockCloudSync.fetchLatestCloudMetadata()).thenAnswer((_) async => null);
      when(() => mockCloudSync.downloadEncryptedBackup()).thenAnswer((_) async => fakePayload);
      // verifyCloudDecrypt succeeds (old key matches)
      when(() => mockSyncUseCase.verifyCloudDecrypt(any(), any())).thenAnswer((_) async => {});
      when(() => mockSyncUseCase.setRecoverySalt(any())).thenAnswer((_) async => {});
      when(() => mockSyncUseCase.execute()).thenAnswer((_) async => false);

      await provider.init();
      await provider.changePassphrase('oldPass123', 'newPass456');

      expect(provider.lastError, isNull);
      verify(() => mockSyncUseCase.verifyCloudDecrypt(fakePayload, any())).called(1);
      verify(() => mockKeyStorage.setCloudSyncKey(any())).called(1);
      verify(() => mockSyncUseCase.execute()).called(1);
    });

    test('changePassphrase sets error when old passphrase is wrong', () async {
      const storedSalt = 'dGVzdHNhbHQ=';
      final fakePayload = Uint8List.fromList([1, 2, 3]);

      when(() => mockPrefs.isCloudSyncEnabled()).thenAnswer((_) async => true);
      when(() => mockPrefs.isRecoveryPassphraseSet()).thenAnswer((_) async => true);
      when(() => mockPrefs.getLastSyncTime()).thenAnswer((_) async => null);
      when(() => mockPrefs.getRecoverySalt()).thenAnswer((_) async => storedSalt);
      when(() => mockCloudSync.authenticate()).thenAnswer((_) async => {});
      when(() => mockCloudSync.fetchLatestCloudMetadata()).thenAnswer((_) async => null);
      when(() => mockCloudSync.downloadEncryptedBackup()).thenAnswer((_) async => fakePayload);
      // verifyCloudDecrypt throws — simulates wrong key
      when(() => mockSyncUseCase.verifyCloudDecrypt(any(), any()))
          .thenThrow(Exception('Integrity check failed: Incorrect key or corrupted backup'));

      await provider.init();
      await provider.changePassphrase('wrongPass', 'newPass456');

      expect(provider.lastError, contains('Old passphrase is incorrect'));
      verifyNever(() => mockKeyStorage.setCloudSyncKey(any()));
    });
  });
}
