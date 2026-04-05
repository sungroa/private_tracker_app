import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';
import 'package:private_tracker_app/domain/repositories/symptom_log_repository.dart';
import 'package:private_tracker_app/domain/repositories/tag_repository.dart';
import 'package:private_tracker_app/data/repositories/symptom_log_repository_impl.dart';
import 'package:private_tracker_app/data/repositories/cycle_log_repository_impl.dart';
import 'package:private_tracker_app/data/repositories/tag_repository_impl.dart';
import 'package:private_tracker_app/presentation/sheets/symptom_logging_sheet.dart';
import 'package:private_tracker_app/presentation/sheets/cycle_logging_sheet.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';
import 'package:private_tracker_app/data/storage/secure_key_storage.dart';
import 'package:private_tracker_app/data/storage/local_database_manager.dart';
import 'package:private_tracker_app/data/storage/backup_restore_service.dart';
import 'package:private_tracker_app/data/storage/data_export_service.dart';
import 'package:private_tracker_app/presentation/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:private_tracker_app/presentation/providers/tag_provider.dart';
import 'package:private_tracker_app/presentation/providers/symptom_provider.dart';
import 'package:private_tracker_app/presentation/providers/cycle_provider.dart';
import 'package:private_tracker_app/data/storage/hive_dtos.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
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
    late EncryptedStorageService storageService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_widget');
      Hive.init(tempDir.path);
      
      mockStorage = MockFlutterSecureStorage();
      storageService = EncryptedStorageService(
        keyStorage: SecureKeyStorage(mockStorage),
        dbManager: LocalDatabaseManager(),
        backupService: BackupRestoreService(),
        exportService: DataExportService(),
      );
      
      final key = Hive.generateSecureKey();
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => base64UrlEncode(key));
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async => {});

      await storageService.initialize(basePath: tempDir.path);
      
      final customTags = storageService.getCustomTags();
      if (customTags.isEmpty) {
        await storageService.addCustomTag('Cramps');
        await storageService.addCustomTag('Bloating');
      }
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('SymptomLoggingSheet shows "Add Log" in create mode', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(
          child: SymptomLoggingSheet(selectedDay: DateTime.now()),
          providers: [
            Provider<EncryptedStorageService>.value(value: storageService),
            Provider<SymptomLogRepository>(create: (_) => SymptomLogRepositoryImpl(storageService)),
            Provider<TagRepository>(create: (_) => TagRepositoryImpl(storageService)),
            ChangeNotifierProvider(create: (_) => SymptomProvider(SymptomLogRepositoryImpl(storageService))),
            ChangeNotifierProvider(create: (context) => TagProvider(context.read<TagRepository>())),
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
        id: 'test-symptom-id',
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
            Provider<EncryptedStorageService>.value(value: storageService),
            Provider<SymptomLogRepository>(create: (_) => SymptomLogRepositoryImpl(storageService)),
            Provider<TagRepository>(create: (_) => TagRepositoryImpl(storageService)),
            ChangeNotifierProvider(create: (_) => SymptomProvider(SymptomLogRepositoryImpl(storageService))),
            ChangeNotifierProvider(create: (context) => TagProvider(context.read<TagRepository>())),
          ],
        ),
      );
      await tester.pump();
      
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Test notes'), findsOneWidget);
      expect(find.text('98.7'), findsOneWidget);
      expect(find.byIcon(Icons.sentiment_very_satisfied), findsOneWidget);
    });

    testWidgets('SymptomLoggingSheet deletion shows confirmation dialog', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final existing = SymptomLog(id: 'delete-id', date: DateTime.now(), symptoms: [], moodRating: 3);
      
      await tester.pumpWidget(
        buildTestableWidget(
          child: SymptomLoggingSheet(selectedDay: existing.date, existingLog: existing),
          providers: [
            Provider<EncryptedStorageService>.value(value: storageService),
            Provider<SymptomLogRepository>(create: (_) => SymptomLogRepositoryImpl(storageService)),
            Provider<TagRepository>(create: (_) => TagRepositoryImpl(storageService)),
            ChangeNotifierProvider(create: (_) => SymptomProvider(SymptomLogRepositoryImpl(storageService))),
            ChangeNotifierProvider(create: (context) => TagProvider(context.read<TagRepository>())),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Delete Daily Log'));
      await tester.pump(); 
      await tester.pump(); 
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 100)); 

      expect(find.text('Delete Entry'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this log? This action cannot be undone.'), findsOneWidget);
    });

    testWidgets('Selecting a symptom and clicking save should persist data', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final date = DateTime(2026, 3, 28);

      await tester.pumpWidget(
        buildTestableWidget(
          child: SymptomLoggingSheet(selectedDay: date),
          providers: [
            Provider<EncryptedStorageService>.value(value: storageService),
            Provider<SymptomLogRepository>(create: (_) => SymptomLogRepositoryImpl(storageService)),
            Provider<TagRepository>(create: (_) => TagRepositoryImpl(storageService)),
            ChangeNotifierProvider(create: (_) => SymptomProvider(SymptomLogRepositoryImpl(storageService))),
            ChangeNotifierProvider(create: (context) => TagProvider(context.read<TagRepository>())),
          ],
        ),
      );

      await tester.pump(); 
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 100)); 

      final crampsChip = find.text('Cramps');
      await tester.tap(crampsChip);
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 200)); 

      final saveButton = find.byKey(const Key('symptom_save_button'));
      
      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future.delayed(const Duration(milliseconds: 100));
      });
      
      await tester.pump(const Duration(seconds: 1)); 

      final logs = storageService.getSymptomLogsForMonth(date);
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

      final symptomBox = storageService.getBox<SymptomLogDto>(LocalDatabaseManager.symptomLogBox);
      await symptomBox.put(existing.id, SymptomLogDto.fromDomain(existing));

      await tester.pumpWidget(
        buildTestableWidget(
          child: SymptomLoggingSheet(selectedDay: date, existingLog: existing),
          providers: [
            Provider<EncryptedStorageService>.value(value: storageService),
            ChangeNotifierProvider(create: (_) => SymptomProvider(SymptomLogRepositoryImpl(storageService))),
          ],
        ),
      );

      await tester.pump(); 
      await tester.pump(); 
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

      final logs = storageService.getSymptomLogs();
      expect(logs.any((l) => l.id == 'test-id-123'), true);
      final updatedLog = logs.firstWhere((l) => l.id == 'test-id-123');
      expect(updatedLog.basalBodyTemperature, 97.85);
    });
  });

  group('CycleLoggingSheet Widget Tests', () {
    late Directory tempDir;
    late MockFlutterSecureStorage mockStorage;
    late EncryptedStorageService storageService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_cycle');
      Hive.init(tempDir.path);
      
      mockStorage = MockFlutterSecureStorage();
      storageService = EncryptedStorageService(
        keyStorage: SecureKeyStorage(mockStorage),
        dbManager: LocalDatabaseManager(),
        backupService: BackupRestoreService(),
        exportService: DataExportService(),
      );
      
      final key = Hive.generateSecureKey();
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => base64UrlEncode(key));
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async => {});

      await storageService.initialize(basePath: tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('CycleLoggingSheet shows "Add Cycle Log" in create mode', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(
          child: CycleLoggingSheet(selectedDay: DateTime(2026, 3, 28)),
          providers: [
            Provider<EncryptedStorageService>.value(value: storageService),
            ChangeNotifierProvider(create: (_) => CycleProvider(
              CycleLogRepositoryImpl(storageService),
              SymptomLogRepositoryImpl(storageService),
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
        id: 'cycle-id',
        startDate: DateTime(2026, 3, 20),
        endDate: DateTime(2026, 3, 25),
        notes: "Cycle notes",
        flowIntensity: 4,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: CycleLoggingSheet(selectedDay: DateTime(2026, 3, 28), existingEvent: existing),
          providers: [
            Provider<EncryptedStorageService>.value(value: storageService),
            ChangeNotifierProvider(create: (_) => CycleProvider(
              CycleLogRepositoryImpl(storageService),
              SymptomLogRepositoryImpl(storageService),
            )),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cycle notes'), findsOneWidget);
      expect(find.text('Mar 20, 2026'), findsOneWidget);
      expect(find.text('Mar 25, 2026'), findsOneWidget);
      expect(find.text('Heavy'), findsOneWidget); 
    });

    testWidgets('CycleLoggingSheet deletion shows confirmation', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final existing = CycleEvent(id: 'del-cycle', startDate: DateTime.now());
      await tester.pumpWidget(
        buildTestableWidget(
          child: CycleLoggingSheet(selectedDay: DateTime.now(), existingEvent: existing),
          providers: [
            Provider<EncryptedStorageService>.value(value: storageService),
            ChangeNotifierProvider(create: (_) => CycleProvider(
              CycleLogRepositoryImpl(storageService),
              SymptomLogRepositoryImpl(storageService),
            )),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Delete Cycle Log'));
      await tester.pump();
      await tester.pump(); 
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
            Provider<EncryptedStorageService>.value(value: storageService),
            ChangeNotifierProvider(create: (_) => CycleProvider(
              CycleLogRepositoryImpl(storageService),
              SymptomLogRepositoryImpl(storageService),
            )),
          ],
        ),
      );

      await tester.pump(); 
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 100)); 

      final saveButton = find.text('Add Cycle Log');
      
      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future.delayed(const Duration(milliseconds: 100));
      });
      
      await tester.pump(const Duration(seconds: 1));

      final logs = storageService.getCycleEvents();
      expect(logs.length, 1);
      expect(logs.first.startDate.year, 2026);
    });
  });
}
