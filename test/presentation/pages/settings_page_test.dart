import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:private_tracker_app/presentation/pages/settings_page.dart';
import 'package:private_tracker_app/presentation/providers/cloud_sync_provider.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/data/storage/backup_orchestrator.dart';
import 'package:private_tracker_app/core/services/auth_service.dart';
import 'package:private_tracker_app/core/services/notification_service.dart';
import 'package:private_tracker_app/core/services/preferences_service.dart';

class MockCloudSyncProvider extends Mock implements CloudSyncProvider {}
class MockEncryptedStorageService extends Mock implements EncryptedStorageService {}
class MockBackupOrchestrator extends Mock implements BackupOrchestrator {}
class MockAuthService extends Mock implements AuthService {}
class MockNotificationService extends Mock implements NotificationService {}
class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late MockCloudSyncProvider mockCloudSyncProvider;
  late MockEncryptedStorageService mockEncryptedStorageService;
  late MockBackupOrchestrator mockBackupOrchestrator;
  late MockAuthService mockAuthService;
  late MockNotificationService mockNotificationService;
  late MockPreferencesService mockPreferencesService;

  setUp(() {
    mockCloudSyncProvider = MockCloudSyncProvider();
    mockEncryptedStorageService = MockEncryptedStorageService();
    mockBackupOrchestrator = MockBackupOrchestrator();
    mockAuthService = MockAuthService();
    mockNotificationService = MockNotificationService();
    mockPreferencesService = MockPreferencesService();

    when(() => mockAuthService.isHardwareSupported()).thenAnswer((_) async => true);
    when(() => mockPreferencesService.isBiometricEnabled()).thenAnswer((_) async => false);
    when(() => mockPreferencesService.isNotificationsEnabled()).thenAnswer((_) async => false);
    when(() => mockPreferencesService.getNotificationTime()).thenAnswer((_) async => const TimeOfDay(hour: 20, minute: 0));
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
    expect(find.text('Daily Reminders'), findsOneWidget);
  });
}
