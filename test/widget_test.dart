import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:private_tracker_app/main.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/core/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('App smoke tests', () {
    late Directory tempDir;
    late MockAuthService mockAuthService;
    late MockFlutterSecureStorage mockStorage;

    setUp(() async {
      mockAuthService = MockAuthService();
      AuthService.instance = mockAuthService;
      
      mockStorage = MockFlutterSecureStorage();
      EncryptedStorageService.instance = EncryptedStorageService.test(mockStorage);
      
      final key = Hive.generateSecureKey();
      when(() => mockStorage.containsKey(key: any(named: 'key'))).thenAnswer((_) async => true);
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => base64UrlEncode(key));

      // Default behavior for smoke test: no biometric lock
      when(() => mockAuthService.isBiometricEnabled()).thenAnswer((_) async => false);
      when(() => mockAuthService.isHardwareSupported()).thenAnswer((_) async => false);

      tempDir = await Directory.systemTemp.createTemp('hive_smoke_test');
      Hive.init(tempDir.path);
      
      await EncryptedStorageService.instance.initialize(basePath: tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('App smoke test renders home page', (WidgetTester tester) async {
      await tester.pumpWidget(const PrivacyTrackerApp());

      // Use explicit pump() calls instead of pumpAndSettle() to avoid
      // hanging on the CircularProgressIndicator that AppLockWrapper
      // shows while _isInitializing is true. The async _checkInitialAuth
      // completes within a few frames (mocked services return instantly),
      // after which the spinner is replaced by the HomePage.
      await tester.pump(); // Trigger initState and start _checkInitialAuth
      await tester.pump(); // Allow async futures (isBiometricEnabled, initialize) to complete
      await tester.pump(); // Render final state after setState(_isInitializing = false)

      // Verify that the title is present in the AppBar.
      expect(find.text('Cycle Tracker'), findsOneWidget);
    });
  });
}
