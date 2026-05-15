import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:private_tracker_app/presentation/pages/settings_page.dart';
import 'package:private_tracker_app/presentation/providers/cloud_sync_provider.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/data/storage/backup_orchestrator.dart';
import 'package:private_tracker_app/core/services/auth_service.dart';
import 'package:private_tracker_app/core/services/notification_orchestrator.dart';
import 'package:private_tracker_app/core/services/notification_service.dart';
import 'package:private_tracker_app/core/services/preferences_service.dart';
import 'package:private_tracker_app/presentation/providers/cycle_provider.dart';

class MockCloudSyncProvider extends Mock implements CloudSyncProvider {}
class MockEncryptedStorageService extends Mock implements EncryptedStorageService {}
class MockBackupOrchestrator extends Mock implements BackupOrchestrator {}
class MockAuthService extends Mock implements AuthService {}
class MockNotificationService extends Mock implements NotificationService {}
class MockPreferencesService extends Mock implements PreferencesService {}
class MockNotificationOrchestrator extends Mock implements NotificationOrchestrator {}
class MockCycleProvider extends Mock implements CycleProvider {}

class FakeDateTime extends Fake implements DateTime {}
class FakeTimeOfDay extends Fake implements TimeOfDay {}

void main() {
  late MockCloudSyncProvider mockCloudSyncProvider;
  late MockEncryptedStorageService mockEncryptedStorageService;
  late MockBackupOrchestrator mockBackupOrchestrator;
  late MockAuthService mockAuthService;
  late MockNotificationService mockNotificationService;
  late MockPreferencesService mockPreferencesService;
  late MockNotificationOrchestrator mockNotificationOrchestrator;
  late MockCycleProvider mockCycleProvider;

  setUpAll(() {
    registerFallbackValue(FakeDateTime());
    registerFallbackValue(FakeTimeOfDay());
  });

  setUp(() {
    mockCloudSyncProvider = MockCloudSyncProvider();
    mockEncryptedStorageService = MockEncryptedStorageService();
    mockBackupOrchestrator = MockBackupOrchestrator();
    mockAuthService = MockAuthService();
    mockNotificationService = MockNotificationService();
    mockPreferencesService = MockPreferencesService();
    mockNotificationOrchestrator = MockNotificationOrchestrator();
    mockCycleProvider = MockCycleProvider();

    when(() => mockNotificationService.cancelNotification(any())).thenAnswer((_) async {});

    when(() => mockAuthService.isHardwareSupported()).thenAnswer((_) async => true);
    when(() => mockPreferencesService.isBiometricEnabled()).thenAnswer((_) async => false);
    when(() => mockPreferencesService.isNotificationsEnabled()).thenAnswer((_) async => false);
    when(() => mockPreferencesService.getNotificationTime()).thenAnswer((_) async => const TimeOfDay(hour: 20, minute: 0));
    
    when(() => mockPreferencesService.isPeriodReminderEnabled()).thenAnswer((_) async => false);
    when(() => mockPreferencesService.getPeriodReminderOffset()).thenAnswer((_) async => 1);
    when(() => mockPreferencesService.getPeriodReminderTime()).thenAnswer((_) async => const TimeOfDay(hour: 9, minute: 0));
    
    when(() => mockPreferencesService.isFertilityReminderEnabled()).thenAnswer((_) async => false);
    when(() => mockPreferencesService.getFertilityReminderOffset()).thenAnswer((_) async => 1);
    when(() => mockPreferencesService.getFertilityReminderTime()).thenAnswer((_) async => const TimeOfDay(hour: 9, minute: 0));

    when(() => mockCycleProvider.trends).thenReturn(null);
    when(() => mockCloudSyncProvider.requiresRecoveryPrompt).thenReturn(false);
    when(() => mockCloudSyncProvider.isOrphanKey).thenReturn(false);
    when(() => mockCloudSyncProvider.isRecoveryEnabled).thenReturn(false);
    when(() => mockCloudSyncProvider.isCloudEnabled).thenReturn(false);
    when(() => mockCloudSyncProvider.isGoogleDriveEnabled).thenReturn(false);
    when(() => mockCloudSyncProvider.isiCloudEnabled).thenReturn(false);
    when(() => mockCloudSyncProvider.isSyncing).thenReturn(false);
    when(() => mockCloudSyncProvider.lastError).thenReturn(null);
    when(() => mockCloudSyncProvider.lastSyncTime).thenReturn(null);
  });

  Widget createSettingsPage() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CloudSyncProvider>.value(value: mockCloudSyncProvider),
        Provider<EncryptedStorageService>.value(value: mockEncryptedStorageService),
        Provider<BackupOrchestrator>.value(value: mockBackupOrchestrator),
        Provider<AuthService>.value(value: mockAuthService),
        Provider<NotificationService>.value(value: mockNotificationService),
        Provider<PreferencesService>.value(value: mockPreferencesService),
        Provider<NotificationOrchestrator>.value(value: mockNotificationOrchestrator),
        ChangeNotifierProvider<CycleProvider>.value(value: mockCycleProvider),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SettingsPage(),
        ),
      ),
    );
  }

  testWidgets('SettingsPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createSettingsPage());
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('REMINDERS'), findsOneWidget);
  });

  testWidgets('Toggling biometric lock calls auth and prefs', (WidgetTester tester) async {
    when(() => mockAuthService.authenticate()).thenAnswer((_) async => true);
    when(() => mockPreferencesService.setBiometricEnabled(any())).thenAnswer((_) async {});

    await tester.pumpWidget(createSettingsPage());
    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch).first;
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    verify(() => mockAuthService.authenticate()).called(1);
    verify(() => mockPreferencesService.setBiometricEnabled(true)).called(1);
    expect(find.text('Biometric lock enabled'), findsOneWidget);
  });

  testWidgets('Clicking export data calls storage and shows success', (WidgetTester tester) async {
    when(() => mockEncryptedStorageService.exportDataToCsv()).thenAnswer((_) async => 'csv_data');
    
    await tester.pumpWidget(createSettingsPage());
    await tester.pumpAndSettle();

    // Scroll to Export Data
    final exportFinder = find.text('Export Data');
    await tester.scrollUntilVisible(exportFinder, 500);
    await tester.tap(exportFinder);
    await tester.pump(); // Start export

    verify(() => mockEncryptedStorageService.exportDataToCsv()).called(1);
  });
}
