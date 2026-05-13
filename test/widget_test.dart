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
import 'package:private_tracker_app/presentation/pages/home_page.dart';
import 'package:private_tracker_app/core/services/service_locator.dart';
import 'package:private_tracker_app/core/services/notification_service.dart';
import 'package:app_links/app_links.dart';

class MockAuthService extends Mock implements AuthService {}
class MockPreferencesService extends Mock implements PreferencesService {}
class MockSecureKeyStorage extends Mock implements SecureKeyStorage {}
class MockAppLinks extends Mock implements AppLinks {}
class MockNotificationService extends Mock implements NotificationService {}

class FakeDateTime extends Fake implements DateTime {}
class FakeTimeOfDay extends Fake implements TimeOfDay {}

void main() {
  group('App smoke tests', () {
    late Directory tempDir;
    late MockAuthService mockAuthService;
    late MockPreferencesService mockPreferencesService;
    late MockSecureKeyStorage mockKeyStorage;
    late MockAppLinks mockAppLinks;
    late MockNotificationService mockNotificationService;
    late LocalDatabaseManager dbManager;

    setUpAll(() {
      registerFallbackValue(FakeDateTime());
      registerFallbackValue(FakeTimeOfDay());
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_smoke_test');
      Hive.init(tempDir.path);

      mockAuthService = MockAuthService();
      mockPreferencesService = MockPreferencesService();
      
      mockKeyStorage = MockSecureKeyStorage();
      mockAppLinks = MockAppLinks();
      mockNotificationService = MockNotificationService();
      dbManager = LocalDatabaseManager();

      // Mock Storage Services
      when(() => mockNotificationService.initialize()).thenAnswer((_) async {});
      when(() => mockNotificationService.cancelNotification(any())).thenAnswer((_) async {});
      when(() => mockNotificationService.scheduleSingleNotification(
        id: any(named: 'id'),
        date: any(named: 'date'),
        time: any(named: 'time'),
        title: any(named: 'title'),
        body: any(named: 'body'),
      )).thenAnswer((_) async {});
      when(() => mockKeyStorage.getOrCreateEncryptionKey()).thenAnswer((_) async => List<int>.filled(32, 0));
      when(() => mockAppLinks.uriLinkStream).thenAnswer((_) => const Stream<Uri>.empty());

      // Default behavior for smoke test: no biometric lock and no cloud sync
      when(() => mockPreferencesService.isBiometricEnabled()).thenAnswer((_) async => false);
      when(() => mockPreferencesService.isCloudSyncEnabled()).thenAnswer((_) async => false);
      when(() => mockPreferencesService.isRecoveryPassphraseSet()).thenAnswer((_) async => false);
      when(() => mockPreferencesService.getLastSyncTime()).thenAnswer((_) async => null);
      when(() => mockAuthService.isHardwareSupported()).thenAnswer((_) async => false);
      when(() => mockPreferencesService.isNotificationsEnabled()).thenAnswer((_) async => false);
      when(() => mockPreferencesService.getNotificationTime()).thenAnswer((_) async => const TimeOfDay(hour: 20, minute: 0));
      when(() => mockPreferencesService.isPeriodReminderEnabled()).thenAnswer((_) async => false);
      when(() => mockPreferencesService.getPeriodReminderOffset()).thenAnswer((_) async => 1);
      when(() => mockPreferencesService.getPeriodReminderTime()).thenAnswer((_) async => const TimeOfDay(hour: 9, minute: 0));
      when(() => mockPreferencesService.isFertilityReminderEnabled()).thenAnswer((_) async => false);
      when(() => mockPreferencesService.getFertilityReminderOffset()).thenAnswer((_) async => 1);
      when(() => mockPreferencesService.getFertilityReminderTime()).thenAnswer((_) async => const TimeOfDay(hour: 9, minute: 0));
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
        final sl = ServiceLocator();
        sl.setup(
          auth: mockAuthService,
          prefs: mockPreferencesService,
          keys: mockKeyStorage,
          db: dbManager,
          customAppLinks: mockAppLinks,
          notifications: mockNotificationService,
        );

        await tester.pumpWidget(PrivacyTrackerApp(
          serviceLocator: sl,
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
