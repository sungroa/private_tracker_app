import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/core/services/app_initializer.dart';
import 'package:private_tracker_app/core/services/auth_service.dart';
import 'package:private_tracker_app/core/services/notification_service.dart';
import 'package:private_tracker_app/core/services/preferences_service.dart';
import 'package:private_tracker_app/core/services/service_locator.dart';
import 'package:private_tracker_app/data/storage/data_sources/cycle_data_source.dart';
import 'package:private_tracker_app/data/storage/data_sources/symptom_data_source.dart';
import 'package:private_tracker_app/data/storage/data_sources/tag_data_source.dart';
import 'package:private_tracker_app/data/storage/hive_dtos.dart';
import 'package:private_tracker_app/data/storage/local_database_manager.dart';
import 'package:private_tracker_app/data/storage/secure_key_storage.dart';
import 'package:private_tracker_app/domain/repositories/donation_repository.dart';
import 'package:private_tracker_app/domain/services/cloud_sync_interface.dart';
import 'package:private_tracker_app/main.dart';
import 'package:private_tracker_app/presentation/pages/home_page.dart';
import 'package:private_tracker_app/presentation/providers/cycle_provider.dart';
import 'package:private_tracker_app/presentation/providers/symptom_provider.dart';
import 'package:private_tracker_app/presentation/providers/tag_provider.dart';
import 'package:provider/provider.dart';

class MockAuthService extends Mock implements AuthService {}

class MockPreferencesService extends Mock implements PreferencesService {}

class MockSecureKeyStorage extends Mock implements SecureKeyStorage {}

class MockAppLinks extends Mock implements AppLinks {}

class MockNotificationService extends Mock implements NotificationService {}

class MockDonationRepository extends Mock implements IDonationRepository {}

class MockCloudSyncInterface extends Mock implements CloudSyncInterface {}

class MockCycleDataSource extends Mock implements CycleDataSource {}

class MockSymptomDataSource extends Mock implements SymptomDataSource {}

class MockTagDataSource extends Mock implements TagDataSource {}

class MockTagBox extends Mock implements Box<CustomTagDto> {}

class MockCycleBox extends Mock implements Box<CycleLogDto> {}

class MockSymptomBox extends Mock implements Box<SymptomLogDto> {}

class MockAppInitializer extends Mock implements AppInitializer {}

class FakeBuildContext extends Fake implements BuildContext {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBuildContext());
  });

  group('Happy Path Integration Tests', () {
    late Directory tempDir;
    late MockAuthService mockAuth;
    late MockPreferencesService mockPrefs;
    late MockSecureKeyStorage mockKeys;
    late MockAppLinks mockLinks;
    late MockNotificationService mockNotify;
    late MockDonationRepository mockDonation;
    late MockCloudSyncInterface mockCloudSync;
    late MockCycleDataSource mockCycleDs;
    late MockSymptomDataSource mockSymptomDs;
    late MockTagDataSource mockTagDs;
    late MockTagBox mockTagBox;
    late MockCycleBox mockCycleBox;
    late MockSymptomBox mockSymptomBox;
    late MockAppInitializer mockInitializer;
    late LocalDatabaseManager dbManager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('happy_path_test');
      Hive.init(tempDir.path);

      mockAuth = MockAuthService();
      mockPrefs = MockPreferencesService();
      mockKeys = MockSecureKeyStorage();
      mockLinks = MockAppLinks();
      mockNotify = MockNotificationService();
      mockDonation = MockDonationRepository();
      mockCloudSync = MockCloudSyncInterface();
      mockCycleDs = MockCycleDataSource();
      mockSymptomDs = MockSymptomDataSource();
      mockTagDs = MockTagDataSource();
      mockTagBox = MockTagBox();
      mockCycleBox = MockCycleBox();
      mockSymptomBox = MockSymptomBox();
      mockInitializer = MockAppInitializer();
      dbManager = LocalDatabaseManager();

      // Mocks
      when(() => mockNotify.initialize()).thenAnswer((_) async {});
      when(() => mockNotify.cancelNotification(any())).thenAnswer((_) async {});
      when(
        () => mockKeys.getOrCreateEncryptionKey(),
      ).thenAnswer((_) async => List<int>.filled(32, 0));
      when(
        () => mockKeys.getOrCreateCloudSyncKey(),
      ).thenAnswer((_) async => List<int>.filled(32, 1));
      when(() => mockLinks.uriLinkStream).thenAnswer((_) => const Stream<Uri>.empty());
      when(() => mockPrefs.isBiometricEnabled()).thenAnswer((_) async => false);
      when(() => mockPrefs.isCloudSyncEnabled()).thenAnswer((_) async => false);
      when(() => mockPrefs.isRecoveryPassphraseSet()).thenAnswer((_) async => false);
      when(() => mockPrefs.isNotificationsEnabled()).thenAnswer((_) async => false);
      when(
        () => mockPrefs.getNotificationTime(),
      ).thenAnswer((_) async => const TimeOfDay(hour: 20, minute: 0));
      when(() => mockPrefs.isPeriodReminderEnabled()).thenAnswer((_) async => false);
      when(() => mockPrefs.getPeriodReminderOffset()).thenAnswer((_) async => 1);
      when(
        () => mockPrefs.getPeriodReminderTime(),
      ).thenAnswer((_) async => const TimeOfDay(hour: 9, minute: 0));
      when(() => mockPrefs.isFertilityReminderEnabled()).thenAnswer((_) async => false);
      when(() => mockPrefs.getFertilityReminderOffset()).thenAnswer((_) async => 1);
      when(
        () => mockPrefs.getFertilityReminderTime(),
      ).thenAnswer((_) async => const TimeOfDay(hour: 9, minute: 0));
      when(() => mockKeys.getSupporterStatus()).thenAnswer((_) async => false);
      when(() => mockDonation.isSupporterStream).thenAnswer((_) => const Stream<bool>.empty());
      when(() => mockDonation.isSupporter()).thenAnswer((_) async => false);
      when(() => mockAuth.isHardwareSupported()).thenAnswer((_) async => false);
      when(() => mockAuth.authenticate()).thenAnswer((_) async => true);

      // Data Source Mocks
      when(() => mockCycleDs.getCycleLogs()).thenAnswer((_) async => []);
      when(() => mockSymptomDs.getSymptomLogs()).thenAnswer((_) async => []);
      when(() => mockTagDs.getCustomTags()).thenAnswer((_) async => []);
      when(() => mockTagDs.box).thenReturn(mockTagBox);
      when(() => mockCycleDs.box).thenReturn(mockCycleBox);
      when(() => mockSymptomDs.box).thenReturn(mockSymptomBox);

      // Box Mocks
      when(() => mockTagBox.values).thenReturn([]);

      // Initializer Mocks
      when(() => mockInitializer.initialize(any())).thenAnswer((_) async {});
      when(() => mockInitializer.isInitialized).thenReturn(true);

      // Cloud Sync Interface mocks
      when(() => mockCloudSync.authenticate()).thenAnswer((_) async {});
      when(() => mockCloudSync.fetchLatestCloudMetadata()).thenAnswer((_) async => null);
    });

    tearDown(() async {
      await dbManager.close();
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('Full flow: App Launch -> Log Period -> Navigation', (WidgetTester tester) async {
      // Set a larger surface size for the test to avoid overflow and off-screen widgets
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.runAsync(() async {
        final sl = ServiceLocator();

        // Setup sl with our mocks
        sl.setup(
          auth: mockAuth,
          prefs: mockPrefs,
          keys: mockKeys,
          db: dbManager,
          customAppLinks: mockLinks,
          notifications: mockNotify,
          donations: mockDonation,
          cycleDs: mockCycleDs,
          symptomDs: mockSymptomDs,
          tagDs: mockTagDs,
          cloudSync: mockCloudSync,
          initializer: mockInitializer,
        );

        await tester.pumpWidget(PrivacyTrackerApp(serviceLocator: sl));

        // Manually trigger initialization since we mocked AppInitializer
        // AppLockWrapper is a child of MultiProvider, so its context has access to providers.
        await tester.pump(); // Ensure AppLockWrapper is built
        final context = tester.element(find.byType(AppLockWrapper));
        await context.read<CycleProvider>().initialize();
        await context.read<SymptomProvider>().initialize();
        await context.read<TagProvider>().initialize();
        await tester.pumpAndSettle();

        // Polling for HomePage
        bool found = false;
        for (int i = 0; i < 150; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.byType(HomePage).evaluate().isNotEmpty) {
            found = true;
            break;
          }
        }

        expect(found, isTrue, reason: 'Should land on HomePage');

        // 1. Verify "PERIOD" button exists and tap it
        final periodButton = find.text('PERIOD');
        expect(periodButton, findsOneWidget);
        await tester.tap(periodButton);
        await tester.pumpAndSettle();

        // 2. Verify Logging sheet appeared
        expect(find.text('Daily Log'), findsOneWidget);

        // Close sheet
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // 3. Navigate to Trends via BottomBar
        final trendsIcon = find.byIcon(Icons.analytics_outlined);
        await tester.tap(trendsIcon);
        await tester.pumpAndSettle();

        expect(find.text('Your Trends'), findsOneWidget);

        // 4. Navigate to Settings
        final settingsIcon = find.byIcon(Icons.settings_outlined);
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        // Check for the "Settings" title with large font (to distinguish from nav label)
        final settingsTitle = find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.data == 'Settings' && (widget.style?.fontSize ?? 0) > 30,
        );
        expect(settingsTitle, findsOneWidget);
      });
    });
  });
}
