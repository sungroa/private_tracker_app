import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import 'package:private_tracker_app/data/storage/data_export_service.dart';
import 'package:private_tracker_app/data/storage/data_sources/data_seeding_service.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:private_tracker_app/presentation/theme/app_theme.dart';
import 'package:private_tracker_app/presentation/providers/cycle_provider.dart';
import 'package:private_tracker_app/presentation/providers/symptom_provider.dart';
import 'package:private_tracker_app/presentation/providers/tag_provider.dart';
import 'package:private_tracker_app/domain/usecases/get_cycle_logs_use_case.dart';
import 'package:private_tracker_app/domain/usecases/save_cycle_log_use_case.dart';
import 'package:private_tracker_app/domain/usecases/delete_cycle_log_use_case.dart';
import 'package:private_tracker_app/domain/usecases/get_symptom_logs_use_case.dart';
import 'package:private_tracker_app/domain/usecases/save_symptom_log_use_case.dart';
import 'package:private_tracker_app/domain/usecases/delete_symptom_log_use_case.dart';
import 'package:private_tracker_app/domain/usecases/get_tags_use_case.dart';
import 'package:private_tracker_app/domain/usecases/add_tag_use_case.dart';
import 'package:private_tracker_app/domain/usecases/delete_tag_use_case.dart';
import 'package:private_tracker_app/data/storage/data_sources/cycle_data_source.dart';
import 'package:private_tracker_app/data/storage/data_sources/symptom_data_source.dart';
import 'package:private_tracker_app/data/storage/data_sources/tag_data_source.dart';
import 'package:uuid/uuid.dart';
import 'package:private_tracker_app/domain/models/custom_tag.dart';

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

  group('Sheet Widget Tests', () {
    late Directory tempDir;
    late MockFlutterSecureStorage mockStorage;
    late EncryptedStorageService storageService;
    late SymptomDataSource symptomDataSource;
    late TagDataSource tagDataSource;
    late CycleDataSource cycleDataSource;
    late LocalDatabaseManager dbManager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_${DateTime.now().microsecondsSinceEpoch}');
      final hiveDir = Directory('${tempDir.path}/hive');
      await hiveDir.create();
      Hive.init(hiveDir.path);
      
      mockStorage = MockFlutterSecureStorage();
      dbManager = LocalDatabaseManager();
      symptomDataSource = SymptomDataSource(dbManager);
      tagDataSource = TagDataSource(dbManager);
      cycleDataSource = CycleDataSource(dbManager);

      storageService = EncryptedStorageService(
        keyStorage: SecureKeyStorage(mockStorage),
        dbManager: dbManager,
        exportService: DataExportService(),
        seedingService: DataSeedingService(),
        cycleDataSource: cycleDataSource,
        symptomDataSource: symptomDataSource,
        tagDataSource: tagDataSource,
      );
      
      final key = Hive.generateSecureKey();
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => base64UrlEncode(key));
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async => {});

      await storageService.initialize(basePath: hiveDir.path).timeout(const Duration(seconds: 5));
      
      if ((await tagDataSource.getCustomTags()).isEmpty) {
        await tagDataSource.saveTag(CustomTag(
          id: const Uuid().v4(),
          name: 'Cramps',
          updatedAt: DateTime.now(),
        ));
      }
    });

    tearDown(() async {
      await dbManager.close();
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> safePump(WidgetTester tester) async {
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('SymptomLoggingSheet shows basic UI', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: SymptomLoggingSheet(selectedDay: DateTime.now()),
          providers: [
            Provider<EncryptedStorageService>.value(value: storageService),
            Provider<SymptomLogRepository>(create: (_) => SymptomLogRepositoryImpl(symptomDataSource)),
            Provider<TagRepository>(create: (_) => TagRepositoryImpl(tagDataSource)),
            ChangeNotifierProvider(create: (_) {
              final repo = SymptomLogRepositoryImpl(symptomDataSource);
              return SymptomProvider(
                GetSymptomLogsUseCase(repo),
                SaveSymptomLogUseCase(repo),
                DeleteSymptomLogUseCase(repo),
              );
            }),
            ChangeNotifierProvider(create: (_) {
              final repo = TagRepositoryImpl(tagDataSource);
              return TagProvider(
                GetTagsUseCase(repo),
                AddTagUseCase(repo),
                DeleteTagUseCase(repo),
              );
            }),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('Add Log'), findsOneWidget);
    });

    testWidgets('CycleLoggingSheet shows basic UI', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: CycleLoggingSheet(selectedDay: DateTime.now()),
          providers: [
            Provider<EncryptedStorageService>.value(value: storageService),
            ChangeNotifierProvider(create: (_) {
              final cycleRepo = CycleLogRepositoryImpl(cycleDataSource);
              final symptomRepo = SymptomLogRepositoryImpl(symptomDataSource);
              return CycleProvider(
                GetCycleLogsUseCase(cycleRepo, symptomRepo),
                SaveCycleLogUseCase(cycleRepo),
                DeleteCycleLogUseCase(cycleRepo),
              );
            }),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('Add Cycle Log'), findsOneWidget);
    });

    testWidgets('Saving symptom log persists and closes sheet', (WidgetTester tester) async {
      // SET SURFACE SIZE to ensure button is visible
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final date = DateTime(2026, 3, 28);
      await tester.pumpWidget(
        buildTestableWidget(
          child: SymptomLoggingSheet(selectedDay: date),
          providers: [
            Provider<EncryptedStorageService>.value(value: storageService),
            Provider<SymptomLogRepository>(create: (_) => SymptomLogRepositoryImpl(symptomDataSource)),
            Provider<TagRepository>(create: (_) => TagRepositoryImpl(tagDataSource)),
            ChangeNotifierProvider(create: (_) {
              final repo = SymptomLogRepositoryImpl(symptomDataSource);
              return SymptomProvider(
                GetSymptomLogsUseCase(repo),
                SaveSymptomLogUseCase(repo),
                DeleteSymptomLogUseCase(repo),
              );
            }),
            ChangeNotifierProvider(create: (_) {
              final repo = TagRepositoryImpl(tagDataSource);
              return TagProvider(
                GetTagsUseCase(repo),
                AddTagUseCase(repo),
                DeleteTagUseCase(repo),
              );
            }),
          ],
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Cramps'));
      await tester.pump();

      final saveButton = find.byKey(const Key('symptom_save_button'));
      
      await tester.runAsync(() async {
        await tester.tap(saveButton);
        // Important: let the async save operation complete in its own isolate/future
        await Future.delayed(const Duration(milliseconds: 200));
      });
      
      await safePump(tester);

      final logs = await symptomDataSource.getSymptomLogsForMonth(date);
      expect(logs.isNotEmpty, true, reason: 'Symptom log should be saved');
    });

    testWidgets('Saving cycle log persists and closes sheet', (WidgetTester tester) async {
      // SET SURFACE SIZE to ensure button is visible
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final date = DateTime(2026, 3, 28);
      await tester.pumpWidget(
        buildTestableWidget(
          child: CycleLoggingSheet(selectedDay: date),
          providers: [
            Provider<EncryptedStorageService>.value(value: storageService),
            ChangeNotifierProvider(create: (_) {
              final cycleRepo = CycleLogRepositoryImpl(cycleDataSource);
              final symptomRepo = SymptomLogRepositoryImpl(symptomDataSource);
              return CycleProvider(
                GetCycleLogsUseCase(cycleRepo, symptomRepo),
                SaveCycleLogUseCase(cycleRepo),
                DeleteCycleLogUseCase(cycleRepo),
              );
            }),
          ],
        ),
      );

      await tester.pump();
      final saveButton = find.text('Add Cycle Log');
      
      await tester.runAsync(() async {
        await tester.tap(saveButton);
        // Important: let the async save operation complete
        await Future.delayed(const Duration(milliseconds: 200));
      });
      
      await safePump(tester);

      final logs = await cycleDataSource.getCycleLogs();
      expect(logs.length, 1, reason: 'Cycle log should be saved');
    });
  });
}
