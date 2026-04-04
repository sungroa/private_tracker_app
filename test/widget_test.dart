import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:private_tracker_app/main.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/models/custom_tag.dart';
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
      
      // We don't call EncryptedStorageService.instance.initialize() here because the app will call it
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('App smoke test renders home page', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const PrivacyTrackerApp());
      await tester.pumpAndSettle();

      // Verify that the title is present in the AppBar.
      expect(find.text('Cycle Tracker'), findsOneWidget);
    });
  });
}
