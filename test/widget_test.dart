// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:private_tracker_app/main.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';

void main() {
  group('App smoke tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_smoke_test');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CycleLogAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SymptomLogAdapter());
      await Hive.openBox<CycleLog>(EncryptedStorageService.cycleLogBox);
      await Hive.openBox<SymptomLog>(EncryptedStorageService.symptomLogBox);
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('App smoke test renders home page', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const PrivacyTrackerApp());
      await tester.pumpAndSettle();

      // Verify that the title is present in the AppBar.
      expect(find.text('Cycle Tracker'), findsOneWidget);
    });
  });
}
