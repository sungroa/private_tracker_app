import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/models/custom_tag.dart';
import 'package:private_tracker_app/presentation/sheets/symptom_logging_sheet.dart';
import 'package:private_tracker_app/presentation/sheets/cycle_logging_sheet.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/presentation/theme/app_theme.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SymptomLoggingSheet Widget Tests', () {
    late Directory tempDir;
    late MockFlutterSecureStorage mockStorage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_widget');
      Hive.init(tempDir.path);
      
      mockStorage = MockFlutterSecureStorage();
      EncryptedStorageService.instance = EncryptedStorageService.test(mockStorage);
      
      final key = Hive.generateSecureKey();
      when(() => mockStorage.containsKey(key: any(named: 'key'))).thenAnswer((_) async => true);
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => base64UrlEncode(key));

      await EncryptedStorageService.instance.initialize(basePath: tempDir.path);
      
      final customTagsBox = EncryptedStorageService.instance.getCustomTagsBox();
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

      expect(find.text('How are you feeling?'), findsOneWidget);
      expect(find.text('Symptoms'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Cramps'), findsOneWidget);
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

      final crampsChip = find.text('Cramps');
      await tester.ensureVisible(crampsChip);
      await tester.tap(crampsChip);
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('symptom_save_button'));
      await tester.ensureVisible(saveButton);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final logs = EncryptedStorageService.instance.getSymptomLogsForMonth(date);
      expect(logs.isNotEmpty, true);
      expect(logs.any((l) => l.symptoms.contains('Cramps')), true);
    });
  });

  group('CycleLoggingSheet Widget Tests', () {
    late Directory tempDir;
    late MockFlutterSecureStorage mockStorage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_cycle');
      Hive.init(tempDir.path);
      
      mockStorage = MockFlutterSecureStorage();
      EncryptedStorageService.instance = EncryptedStorageService.test(mockStorage);
      
      final key = Hive.generateSecureKey();
      when(() => mockStorage.containsKey(key: any(named: 'key'))).thenAnswer((_) async => true);
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => base64UrlEncode(key));

      await EncryptedStorageService.instance.initialize(basePath: tempDir.path);
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
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final logs = EncryptedStorageService.instance.getCycleLogs();
      expect(logs.length, 1);
      expect(logs.first.startDate.year, 2026);
    });
  });
}
