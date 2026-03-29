import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/models/custom_tag.dart';
import 'package:private_tracker_app/presentation/sheets/symptom_logging_sheet.dart';
import 'package:private_tracker_app/presentation/sheets/cycle_logging_sheet.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/presentation/theme/app_theme.dart';

void main() {
  group('SymptomLoggingSheet Widget Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_widget');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CycleLogAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SymptomLogAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CustomTagAdapter());

      await Hive.openBox<CycleLog>(EncryptedStorageService.cycleLogBox);
      await Hive.openBox<SymptomLog>(EncryptedStorageService.symptomLogBox);
      final customTagsBox = await Hive.openBox<CustomTag>(EncryptedStorageService.customTagBox);
      
      // Pre-populate for test
      if (customTagsBox.isEmpty) {
        await customTagsBox.addAll([
          CustomTag(name: 'Cramps', isDefault: true),
          CustomTag(name: 'Bloating', isDefault: true),
        ]);
      }
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('SymptomLoggingSheet renders all core components', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SymptomLoggingSheet(selectedDay: DateTime.now()),
          ),
        ),
      );

      // Verify header text
      expect(find.text('How are you feeling?'), findsOneWidget);
      expect(find.text('Symptoms'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);

      // Verify mood icons (at least 5 should be present)
      expect(find.byIcon(Icons.sentiment_very_satisfied), findsOneWidget);
      expect(find.byIcon(Icons.sentiment_very_dissatisfied), findsOneWidget);

      // Verify symptom chips
      expect(find.text('Cramps'), findsOneWidget);
      expect(find.text('Bloating'), findsOneWidget);

      // Verify save button
      expect(find.text('Save Log'), findsOneWidget);
    });

    testWidgets('Selecting a symptom and clicking save should persist data', (WidgetTester tester) async {
      final date = DateTime(2026, 3, 28);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SymptomLoggingSheet(selectedDay: date),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on 'Cramps' chip - ensure visibility if scrolling is needed
      final crampsChip = find.text('Cramps');
      await tester.ensureVisible(crampsChip);
      await tester.tap(crampsChip);
      await tester.pumpAndSettle();

      // Tap on 'Save Log' button using key for reliability
      final saveButton = find.byKey(const Key('symptom_save_button'));
      await tester.ensureVisible(saveButton);

      await tester.runAsync(() async {
        await tester.tap(saveButton);
        // Use a sufficient delay similar to the successful cycle test
        await Future.delayed(const Duration(milliseconds: 500));
      });
      
      await tester.pumpAndSettle();

      // Final verification
      final logs = EncryptedStorageService.getSymptomLogsForMonth(date);
      expect(logs.isNotEmpty, true, reason: "Expected at least one log saved in Hive for $date");
      expect(logs.any((l) => l.symptoms.contains('Cramps')), true, reason: "Log should contain the selected symptom");
    });
  });

  group('CycleLoggingSheet Widget Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_cycle');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CycleLogAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SymptomLogAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CustomTagAdapter());
      await Hive.openBox<CycleLog>(EncryptedStorageService.cycleLogBox);
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('CycleLoggingSheet renders core components', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CycleLoggingSheet(selectedDay: DateTime(2026, 3, 28)),
          ),
        ),
      );

      expect(find.text('Log Your Cycle'), findsOneWidget);
      expect(find.text('Started On'), findsOneWidget);
      expect(find.text('Ended On'), findsOneWidget);
      expect(find.text('Save Cycle Info'), findsOneWidget);
    });

    testWidgets('Saving cycle log persists data in Hive', (WidgetTester tester) async {
      final date = DateTime(2026, 3, 28);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CycleLoggingSheet(selectedDay: date),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final saveButton = find.text('Save Cycle Info');
      expect(saveButton, findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future.delayed(const Duration(milliseconds: 300));
      });

      await tester.pumpAndSettle();

      final logs = EncryptedStorageService.getCycleLogs();
      expect(logs.length, 1);
      expect(logs.first.startDate.year, 2026);
      expect(logs.first.startDate.month, 3);
      expect(logs.first.startDate.day, 28);
    });
  });
}
