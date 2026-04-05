import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/presentation/pages/partner_mode_page.dart';
import 'package:private_tracker_app/data/storage/partner_storage_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await PartnerStorageService.initialize();
  });

  group('PartnerModePage Widget Tests', () {
    testWidgets('Should display empty state when no data exists', (WidgetTester tester) async {
      await PartnerStorageService.clearPartnerData();

      await tester.pumpWidget(const MaterialApp(
        home: PartnerModePage(),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Partner Mode'), findsOneWidget);
      expect(find.text('Scan QR Code'), findsOneWidget);
    });
  });
}
