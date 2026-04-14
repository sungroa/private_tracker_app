import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:private_tracker_app/main.dart';
import 'package:private_tracker_app/core/services/auth_service.dart';
import 'package:private_tracker_app/core/services/preferences_service.dart';
import 'package:private_tracker_app/data/storage/secure_key_storage.dart';
import 'package:private_tracker_app/data/storage/local_database_manager.dart';
import 'package:private_tracker_app/data/storage/partner_storage_service.dart';
import 'package:private_tracker_app/presentation/pages/home_page.dart';
import 'package:private_tracker_app/core/services/service_locator.dart';
import 'package:app_links/app_links.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockLocalAuthentication extends Mock implements LocalAuthentication {}
class MockAppLinks extends Mock implements AppLinks {}
class MockAuthService extends Mock implements AuthService {}
class MockPreferencesService extends Mock implements PreferencesService {}
class MockPathProviderPlatform extends Mock with MockPlatformInterfaceMixin implements PathProviderPlatform {}

void main() {
  late Directory tempDir;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockAppLinks mockAppLinks;
  late MockAuthService mockAuthService;
  late MockPreferencesService mockPreferencesService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('provider_scope_test');
    Hive.init(tempDir.path);

    final mockPathProvider = MockPathProviderPlatform();
    PathProviderPlatform.instance = mockPathProvider;
    when(() => mockPathProvider.getTemporaryPath()).thenAnswer((_) async => tempDir.path);
    when(() => mockPathProvider.getApplicationDocumentsPath()).thenAnswer((_) async => tempDir.path);

    mockSecureStorage = MockFlutterSecureStorage();
    mockAppLinks = MockAppLinks();
    mockAuthService = MockAuthService();
    mockPreferencesService = MockPreferencesService();

    // Mock AppLinks stream
    when(() => mockAppLinks.uriLinkStream).thenAnswer((_) => const Stream<Uri>.empty());

    // Setup MockPreferencesService
    when(() => mockPreferencesService.isBiometricEnabled()).thenAnswer((_) async => false);
    when(() => mockPreferencesService.isCloudSyncEnabled()).thenAnswer((_) async => false);
    when(() => mockPreferencesService.getLastSyncTime()).thenAnswer((_) async => null);

    // Open unencrypted box for PartnerModePage
    await Hive.openBox('partner_data');
    
    final key = Hive.generateSecureKey();
    when(() => mockSecureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => base64UrlEncode(key));
    when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async => {});
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('Architecture: Pushed route can access Provider above MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<String>(create: (_) => "Proof"),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => Consumer<String>(
                    builder: (context, value, child) => Text(value),
                  )),
                );
              },
              child: const Text("Push"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Push"));
    await tester.pumpAndSettle();
    expect(find.text("Proof"), findsOneWidget);
  });

  testWidgets('Integration: Pushed route can access PartnerStorageService', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final sl = ServiceLocator();
      sl.setup(
        keys: SecureKeyStorage(mockSecureStorage),
        db: LocalDatabaseManager(),
        auth: mockAuthService,
        prefs: mockPreferencesService,
        customAppLinks: mockAppLinks,
      );

      await tester.pumpWidget(PrivacyTrackerApp(
        serviceLocator: sl,
      ));
      
      // Advance beyond the splash/loading screen
      int retry = 0;
      while (find.byType(HomePage).evaluate().isEmpty && retry < 100) {
        await tester.pump(const Duration(milliseconds: 100));
        
        if (retry % 10 == 0) {
          // Allow real async tasks to progress
          await Future.delayed(const Duration(milliseconds: 50));
        }
        retry++;
      }
    });

    expect(find.byType(HomePage), findsOneWidget);

    final BuildContext context = tester.element(find.byType(HomePage));
    final NavigatorState navigator = Navigator.of(context);

    await tester.runAsync(() async {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => Consumer<PartnerStorageService>(
            builder: (context, service, _) => const Text('PartnerServiceFound'),
          ),
        ),
      );
      
      // Allow the navigator to process the push and animations
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        await Future.delayed(const Duration(milliseconds: 10));
      }
    });

    expect(find.text('PartnerServiceFound'), findsOneWidget);
  });
}
