import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:private_tracker_app/domain/models/custom_tag.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/presentation/sheets/symptom_logging_sheet.dart';
import 'package:private_tracker_app/presentation/sheets/cycle_logging_sheet.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/presentation/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:private_tracker_app/presentation/providers/symptom_provider.dart';
import 'package:private_tracker_app/presentation/providers/cycle_provider.dart';
import 'package:private_tracker_app/data/repositories/symptom_log_repository_impl.dart';
import 'package:private_tracker_app/data/repositories/cycle_log_repository_impl.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  // Helper to wrap widgets for testing. Uses a nested Navigator
  // to ensure Navigator.pop() doesn't pop the root test route.
  Widget buildTestableWidget({
    required Widget child,
    required List<SingleChildWidget> providers,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MultiProvider(
        providers: providers,
        child: Scaffold(
          body: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => child,
            ),
          ),
        ),
      ),
    );
  }

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
      EncryptedStorageService.resetForTesting();
    });

    testWidgets('SymptomLoggingSheet shows "Add Log" in create mode', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(
          child: SymptomLoggingSheet(selectedDay: DateTime.now()),
          providers: [
            ChangeNotifierProvider(create: (_) => SymptomProvider(SymptomLogRepositoryImpl(EncryptedStorageService.instance))),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('Add Log'), findsOneWidget);
    });

    testWidgets('SymptomLoggingSheet shows "Save Changes" and pre-populates in edit mode', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final existing = SymptomLog(
        date: DateTime.now(),
        symptoms: ['Cramps'],
        moodRating: 5,
        notes: "Test notes",
        basalBodyTemperature: 98.7,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: SymptomLoggingSheet(selectedDay: existing.date, existingLog: existing),
          providers: [
            ChangeNotifierProvider(create: (_) => SymptomProvider(SymptomLogRepositoryImpl(EncryptedStorageService.instance))),
          ],
        ),
      );
      await tester.pump();
      
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Test notes'), findsOneWidget);
      expect(find.text('98.7'), findsOneWidget);
      
      // Verify mood rating circle is selected (Simplified check by finding the icon)
      expect(find.byIcon(Icons.sentiment_very_satisfied), findsOneWidget);
    });

    testWidgets('SymptomLoggingSheet deletion shows confirmation dialog', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final existing = SymptomLog(date: DateTime.now(), symptoms: [], moodRating: 3);
      
      await tester.pumpWidget(
        buildTestableWidget(
          child: SymptomLoggingSheet(selectedDay: existing.date, existingLog: existing),
          providers: [
            ChangeNotifierProvider(create: (_) => SymptomProvider(SymptomLogRepositoryImpl(EncryptedStorageService.instance))),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Delete Daily Log'));
      await tester.pump(); // Start dialog animation
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Delete entry?'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
    });

    testWidgets('Selecting a symptom and clicking save should persist data', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final date = DateTime(2026, 3, 28);

      await tester.pumpWidget(
        buildTestableWidget(
          child: SymptomLoggingSheet(selectedDay: date),
          providers: [
            ChangeNotifierProvider(create: (_) => SymptomProvider(SymptomLogRepositoryImpl(EncryptedStorageService.instance))),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final crampsChip = find.text('Cramps');
      await tester.tap(crampsChip);
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 200)); // Finish animation

      final saveButton = find.byKey(const Key('symptom_save_button'));
      
      // Use runAsync to allow real async operations (like Hive/Crypto) to complete
      await tester.runAsync(() async {
        await tester.tap(saveButton);
        // Give some real time for microtasks/futures to resolve
        await Future.delayed(const Duration(milliseconds: 100));
      });
      
      // Pump to process the Navigator.pop() and dismissal animation
      await tester.pump(const Duration(seconds: 1)); 

      final logs = EncryptedStorageService.instance.getSymptomLogsForMonth(date);
      expect(logs.isNotEmpty, true);
      expect(logs.any((l) => l.symptoms.contains('Cramps')), true);
    });

    testWidgets('Editing an existing log\'s BBT should persist the new decimal value', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final date = DateTime(2026, 3, 28);
      final existing = SymptomLog(
        id: 'test-id-123',
        date: date,
        symptoms: [],
        moodRating: 3,
        basalBodyTemperature: 98.6,
      );

      // Pre-populate the box with the existing log
      final symptomBox = EncryptedStorageService.instance.getSymptomLogsBox();
      await symptomBox.put(existing.id, existing);

      await tester.pumpWidget(
        buildTestableWidget(
          child: SymptomLoggingSheet(selectedDay: date, existingLog: existing),
          providers: [
            ChangeNotifierProvider(create: (_) => SymptomProvider(SymptomLogRepositoryImpl(EncryptedStorageService.instance))),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final bbtField = find.byKey(const Key('bbt_field'));
      await tester.enterText(bbtField, '97.85');
      await tester.pump();

      final saveButton = find.byKey(const Key('symptom_save_button'));
      await tester.dragUntilVisible(saveButton, find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pump();
      
      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future.delayed(const Duration(seconds: 1));
      });
      
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final logs = EncryptedStorageService.instance.getSymptomLogs();
      expect(logs.any((l) => l.id == 'test-id-123'), true);
      final updatedLog = logs.firstWhere((l) => l.id == 'test-id-123');
      expect(updatedLog.basalBodyTemperature, 97.85);
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
      EncryptedStorageService.resetForTesting();
    });

    testWidgets('CycleLoggingSheet shows "Add Cycle Log" in create mode', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(
          child: CycleLoggingSheet(selectedDay: DateTime(2026, 3, 28)),
          providers: [
            ChangeNotifierProvider(create: (_) => CycleProvider(
              CycleLogRepositoryImpl(EncryptedStorageService.instance),
              SymptomLogRepositoryImpl(EncryptedStorageService.instance),
            )),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('Add Cycle Log'), findsOneWidget);
    });

    testWidgets('CycleLoggingSheet shows "Save Changes" and pre-populates in edit mode', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final existing = CycleEvent(
        startDate: DateTime(2026, 3, 20),
        endDate: DateTime(2026, 3, 25),
        notes: "Cycle notes",
        flowIntensity: 4,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: CycleLoggingSheet(selectedDay: DateTime(2026, 3, 28), existingEvent: existing),
          providers: [
            ChangeNotifierProvider(create: (_) => CycleProvider(
              CycleLogRepositoryImpl(EncryptedStorageService.instance),
              SymptomLogRepositoryImpl(EncryptedStorageService.instance),
            )),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cycle notes'), findsOneWidget);
      expect(find.text('Mar 20, 2026'), findsOneWidget);
      expect(find.text('Mar 25, 2026'), findsOneWidget);
      expect(find.text('Heavy'), findsOneWidget); // Flow label 4
    });

    testWidgets('CycleLoggingSheet deletion shows confirmation', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final existing = CycleEvent(startDate: DateTime.now());
      await tester.pumpWidget(
        buildTestableWidget(
          child: CycleLoggingSheet(selectedDay: DateTime.now(), existingEvent: existing),
          providers: [
            ChangeNotifierProvider(create: (_) => CycleProvider(
              CycleLogRepositoryImpl(EncryptedStorageService.instance),
              SymptomLogRepositoryImpl(EncryptedStorageService.instance),
            )),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Delete Cycle Log'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Delete Cycle Log?'), findsOneWidget);
    });

    testWidgets('Saving cycle log persists data in Hive', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final date = DateTime(2026, 3, 28);
      await tester.pumpWidget(
        buildTestableWidget(
          child: CycleLoggingSheet(selectedDay: date),
          providers: [
            ChangeNotifierProvider(create: (_) => CycleProvider(
              CycleLogRepositoryImpl(EncryptedStorageService.instance),
              SymptomLogRepositoryImpl(EncryptedStorageService.instance),
            )),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final saveButton = find.text('Add Cycle Log');
      
      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future.delayed(const Duration(milliseconds: 100));
      });
      
      await tester.pump(const Duration(seconds: 1));

      final logs = EncryptedStorageService.instance.getCycleEvents();
      expect(logs.length, 1);
      expect(logs.first.startDate.year, 2026);
    });
  });
}
