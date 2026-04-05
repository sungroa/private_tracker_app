import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:private_tracker_app/main.dart';
import 'package:private_tracker_app/core/services/auth_service.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/presentation/pages/home_page.dart';
import 'package:private_tracker_app/presentation/pages/partner_mode_page.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockLocalAuthentication extends Mock implements LocalAuthentication {}
class MockEncryptedStorageService extends Mock implements EncryptedStorageService {}

void main() {
  late Directory tempDir;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockLocalAuthentication mockLocalAuth;
  late MockEncryptedStorageService mockStorageService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('provider_scope_test');
    Hive.init(tempDir.path);

    mockSecureStorage = MockFlutterSecureStorage();
    mockLocalAuth = MockLocalAuthentication();
    mockStorageService = MockEncryptedStorageService();

    // Inject Mocks
    AuthService.instance = AuthService.test(mockLocalAuth, mockSecureStorage);
    EncryptedStorageService.instance = mockStorageService;

    // Mock Storage Service
    when(() => mockStorageService.initialize(basePath: any(named: 'basePath'))).thenAnswer((_) async {});
    when(() => mockStorageService.getCycleEvents()).thenReturn([]);
    when(() => mockStorageService.getSymptomLogs()).thenReturn([]);
    
    // Open unencrypted box for PartnerModePage
    await Hive.openBox('partner_data');

    // Mock Auth Preferences (Biometric Disabled by default to skip auth screen)
    when(() => mockSecureStorage.read(key: 'is_biometric_enabled')).thenAnswer((_) async => 'false');
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

  testWidgets('Integration: Pushed PartnerModePage can access providers', (WidgetTester tester) async {
    // 1. Build the full app
    await tester.pumpWidget(const PrivacyTrackerApp());
    
    // Advance beyond the splash/loading screen
    int retry = 0;
    while (find.byType(HomePage).evaluate().isEmpty && retry < 10) {
      await tester.pump(const Duration(milliseconds: 200));
      retry++;
    }

    expect(find.byType(HomePage), findsOneWidget);

    // 2. Simulate pushing PartnerModePage via navigator (finding context below MaterialApp)
    final BuildContext context = tester.element(find.byType(HomePage));
    final NavigatorState navigator = Navigator.of(context);

    navigator.push(
      MaterialPageRoute(
        builder: (context) => const PartnerModePage(
          initialPayload: 'test',
          initialKey: 'test',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 3. Verify no ProviderNotFoundException occurred
    expect(find.byType(PartnerModePage), findsOneWidget);
  });
}

