import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/main.dart';
import 'package:private_tracker_app/core/services/auth_service.dart';
import 'package:private_tracker_app/core/services/preferences_service.dart';
import 'package:private_tracker_app/data/storage/secure_key_storage.dart';
import 'package:private_tracker_app/data/storage/local_database_manager.dart';
import 'package:private_tracker_app/data/storage/backup_restore_service.dart';
import 'package:private_tracker_app/data/storage/data_export_service.dart';
import 'package:private_tracker_app/presentation/pages/home_page.dart';
import 'package:app_links/app_links.dart';

class MockAuthService extends Mock implements AuthService {}
class MockPreferencesService extends Mock implements PreferencesService {}
class MockSecureKeyStorage extends Mock implements SecureKeyStorage {}
class MockAppLinks extends Mock implements AppLinks {}

void main() {
  group('App smoke tests', () {
    late Directory tempDir;
    late MockAuthService mockAuthService;
    late MockPreferencesService mockPreferencesService;
    late MockSecureKeyStorage mockKeyStorage;
    late MockAppLinks mockAppLinks;
    late LocalDatabaseManager dbManager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_smoke_test');
      Hive.init(tempDir.path);

      mockAuthService = MockAuthService();
      mockPreferencesService = MockPreferencesService();
      
      mockKeyStorage = MockSecureKeyStorage();
      mockAppLinks = MockAppLinks();
      dbManager = LocalDatabaseManager();

      // Mock Storage Services
      when(() => mockKeyStorage.getOrCreateEncryptionKey()).thenAnswer((_) async => List<int>.filled(32, 0));
      when(() => mockAppLinks.uriLinkStream).thenAnswer((_) => const Stream<Uri>.empty());

      // Default behavior for smoke test: no biometric lock
      when(() => mockPreferencesService.isBiometricEnabled()).thenAnswer((_) async => false);
      when(() => mockAuthService.isHardwareSupported()).thenAnswer((_) async => false);
    });

    tearDown(() async {
      await dbManager.close();
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('App smoke test renders home page', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(PrivacyTrackerApp(
          keyStorage: mockKeyStorage,
          dbManager: dbManager,
          backupService: BackupRestoreService(),
          exportService: DataExportService(),
          appLinks: mockAppLinks,
          storageBasePath: tempDir.path,
          authService: mockAuthService,
          preferencesService: mockPreferencesService,
        ));

        // Initial pump to start initialization
        await tester.pump();
        
        // Wait for initialization and animations to complete
        int retry = 0;
        bool found = false;
        while (retry < 150) { 
          // Real-time pump to let microtasks work
          await tester.pump(const Duration(milliseconds: 100));
          
          if (find.text('Cycle Tracker').evaluate().isNotEmpty) {
            found = true;
            break;
          }
          
          if (retry % 10 == 0) {
             final currentText = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).join(', ');
             debugPrint("Smoke test polling [retry $retry], found text: $currentText");
             // Add a real-time delay to let runAsync tasks progress
             await Future.delayed(const Duration(milliseconds: 50));
          }
          retry++;
        }
        
        // Final pump for any remaining micro-animations
        await tester.pump(const Duration(seconds: 1));
        
        if (!found) {
          final allText = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).join(', ');
          debugPrint("FINAL Available text in tree: $allText");
        }
        
        expect(found, isTrue, reason: "Cycle Tracker should be found after initialization.");
        expect(find.text('Cycle Tracker'), findsOneWidget);
        expect(find.byType(HomePage), findsOneWidget);
      });
    });
    group('Diagnostics', () {
      test('Initialization stability', () async {
        await dbManager.initialize(encryptionKey: List<int>.filled(32, 0), basePath: tempDir.path);
        expect(dbManager.isInitialized, isTrue);
        await dbManager.close();
        expect(dbManager.isInitialized, isFalse);
      });
    });
  });
}
