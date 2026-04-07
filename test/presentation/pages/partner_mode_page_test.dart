import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/presentation/pages/partner_mode_page.dart';
import 'package:private_tracker_app/data/storage/partner_storage_service.dart';
import 'package:private_tracker_app/data/storage/local_database_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:io';

void main() {
  late Directory tempDir;
  late PartnerStorageService partnerService;
  late LocalDatabaseManager dbManager;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('partner_mode_test');
    Hive.init(tempDir.path);
    dbManager = LocalDatabaseManager();
    await dbManager.initialize(
      basePath: tempDir.path, 
      encryptionKey: Hive.generateSecureKey(),
    ).timeout(const Duration(seconds: 5));
    
    partnerService = PartnerStorageService(dbManager);
  });

  tearDown(() async {
    await dbManager.close();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PartnerModePage Widget Tests', () {
    testWidgets('Should display empty state when no data exists', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await partnerService.clearPartnerData();
      });

      await tester.pumpWidget(MaterialApp(
        home: Provider<PartnerStorageService>.value(
          value: partnerService,
          child: const PartnerModePage(),
        ),
      ));

      // Initial pump to let initState run
      await tester.pump();
      
      // Wait for initialization
      int retry = 0;
      bool found = false;
      while (retry < 50) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('Partner Mode').evaluate().isNotEmpty) {
          found = true;
          break;
        }
        retry++;
      }

      expect(found, isTrue, reason: "Partner Mode text should be found");
      expect(find.text('SCAN QR CODE'), findsOneWidget);
    });
  });
}
