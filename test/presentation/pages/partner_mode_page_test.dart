import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/presentation/pages/partner_mode_page.dart';
import 'package:private_tracker_app/data/storage/partner_storage_service.dart';
import 'package:private_tracker_app/data/storage/local_database_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:io';

class MockLocalDatabaseManager extends Mock implements LocalDatabaseManager {}

void main() {
  late Directory tempDir;
  late PartnerStorageService partnerService;
  late LocalDatabaseManager dbManager;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('partner_mode_test');
    Hive.init(tempDir.path);
    dbManager = LocalDatabaseManager();
    // We need to actually initialize it to open the boxes
    await dbManager.initialize(basePath: tempDir.path, encryptionKey: Hive.generateSecureKey());
    partnerService = PartnerStorageService(dbManager);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PartnerModePage Widget Tests', () {
    testWidgets('Should display empty state when no data exists', (WidgetTester tester) async {
      await partnerService.clearPartnerData();

      await tester.pumpWidget(MaterialApp(
        home: Provider<PartnerStorageService>.value(
          value: partnerService,
          child: const PartnerModePage(),
        ),
      ));

      // Use pump with duration to avoid timing out on infinite animations like CircularProgressIndicator
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Partner Mode'), findsOneWidget);
      expect(find.text('SCAN QR CODE'), findsOneWidget);
    });
  });
}
