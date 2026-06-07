import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:mocktail/mocktail.dart';

import 'package:private_tracker_app/data/storage/google_drive_sync_repository.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthorizationClient extends Mock implements GoogleSignInAuthorizationClient {}
class MockDriveApi extends Mock implements drive.DriveApi {}
class MockFilesResource extends Mock implements drive.FilesResource {}
class MockFile extends Mock implements drive.File {}
class MockFileList extends Mock implements drive.FileList {}
class MockMedia extends Mock implements drive.Media {}

void main() {
  late GoogleDriveSyncRepository repository;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockGoogleSignInAccount mockGoogleSignInAccount;
  late MockGoogleSignInAuthorizationClient mockAuthClient;
  late MockDriveApi mockDriveApi;
  late MockFilesResource mockFilesResource;

  setUpAll(() {
    registerFallbackValue(drive.File());
    registerFallbackValue(drive.Media(const Stream.empty(), 0));
  });

  setUp(() {
    mockGoogleSignIn = MockGoogleSignIn();
    mockGoogleSignInAccount = MockGoogleSignInAccount();
    mockAuthClient = MockGoogleSignInAuthorizationClient();
    mockDriveApi = MockDriveApi();
    mockFilesResource = MockFilesResource();

    when(() => mockDriveApi.files).thenReturn(mockFilesResource);

    repository = GoogleDriveSyncRepository(googleSignIn: mockGoogleSignIn);
  });

  group('GoogleDriveSyncRepository', () {
    test('authenticate() successfully sets up auth client', () async {
      // No initialize() stub needed: initialize() is called once at app
      // startup in main(), not inside authenticate().
      when(() => mockGoogleSignIn.attemptLightweightAuthentication())
          .thenAnswer((_) async => null);
      when(() => mockGoogleSignIn.authenticate(scopeHint: any(named: 'scopeHint')))
          .thenAnswer((_) async => mockGoogleSignInAccount);
      when(() => mockGoogleSignInAccount.authorizationClient)
          .thenReturn(mockAuthClient);

      when(() => mockAuthClient.authorizationHeaders(
            any(),
            promptIfNecessary: any(named: 'promptIfNecessary'),
          )).thenAnswer((_) async => {'Authorization': 'Bearer test_token'});

      await repository.authenticate();

      // initialize() is no longer called inside authenticate() — it lives in main().
      verifyNever(
          () => mockGoogleSignIn.initialize(serverClientId: any(named: 'serverClientId')));
      verify(() => mockGoogleSignIn.authenticate(scopeHint: any(named: 'scopeHint')))
          .called(1);
      verify(() => mockAuthClient.authorizationHeaders(any(), promptIfNecessary: false))
          .called(1);
    });

    test('fetchLatestCloudChecksum() returns checksum if backup exists', () async {
      repository.setMockDriveApi(mockDriveApi);
      
      final fileList = MockFileList();
      final mockFile = MockFile();
      when(() => mockFile.appProperties).thenReturn({'checksum': 'test_checksum_123'});
      when(() => mockFile.createdTime).thenReturn(DateTime.now());
      when(() => fileList.files).thenReturn([mockFile]);
      
      when(() => mockFilesResource.list(
        q: any(named: 'q'),
        spaces: 'appDataFolder',
        $fields: '*',
      )).thenAnswer((_) async => fileList);

      final checksum = await repository.fetchLatestCloudChecksum();

      expect(checksum, 'test_checksum_123');
      verify(() => mockFilesResource.list(
        q: any(named: 'q'),
        spaces: 'appDataFolder',
        $fields: '*',
      )).called(1);
    });

    test('uploadEncryptedBackup() creates new and deletes older backups', () async {
      repository.setMockDriveApi(mockDriveApi);

      final payload = Uint8List.fromList([1, 2, 3]);

      // Mock create
      final newMockFile = MockFile();
      when(() => newMockFile.id).thenReturn('new_id');
      when(() => mockFilesResource.create(
        any(),
        uploadMedia: any(named: 'uploadMedia')
      )).thenAnswer((_) async => newMockFile);

      // Mock list
      final oldMockFile = MockFile();
      when(() => oldMockFile.id).thenReturn('old_id');
      final fileList = MockFileList();
      when(() => fileList.files).thenReturn([oldMockFile, newMockFile]);
      
      when(() => mockFilesResource.list(
        q: any(named: 'q'),
        spaces: 'appDataFolder',
        $fields: '*',
      )).thenAnswer((_) async => fileList);

      // Mock delete
      when(() => mockFilesResource.delete(any())).thenAnswer((_) async => Future.value());

      await repository.uploadEncryptedBackup(payload, 'test_upload_checksum');

      verify(() => mockFilesResource.create(
        any(),
        uploadMedia: any(named: 'uploadMedia')
      )).called(1);

      verify(() => mockFilesResource.list(
        q: any(named: 'q'),
        spaces: 'appDataFolder',
        $fields: '*',
      )).called(1);

      // Verify old file was deleted
      verify(() => mockFilesResource.delete('old_id')).called(1);
    });

    test('downloadEncryptedBackup() downloads latest file successfully', () async {
      repository.setMockDriveApi(mockDriveApi);

      // Mock list
      final mockFile = MockFile();
      when(() => mockFile.id).thenReturn('target_id');
      when(() => mockFile.createdTime).thenReturn(DateTime.now());
      
      final fileList = MockFileList();
      when(() => fileList.files).thenReturn([mockFile]);
      
      when(() => mockFilesResource.list(
        q: any(named: 'q'),
        spaces: 'appDataFolder',
        $fields: '*',
      )).thenAnswer((_) async => fileList);

      // Mock get
      final mockMedia = MockMedia();
      when(() => mockMedia.stream).thenAnswer((_) => Stream.fromIterable([
        [1, 2, 3]
      ]));
      
      when(() => mockFilesResource.get(
        'target_id',
        downloadOptions: drive.DownloadOptions.fullMedia,
      )).thenAnswer((_) async => mockMedia);

      final bytes = await repository.downloadEncryptedBackup();

      expect(bytes, [1, 2, 3]);

      verify(() => mockFilesResource.list(
        q: any(named: 'q'),
        spaces: 'appDataFolder',
        $fields: '*',
      )).called(1);

      verify(() => mockFilesResource.get(
        'target_id',
        downloadOptions: drive.DownloadOptions.fullMedia,
      )).called(1);
    });
  });
}
