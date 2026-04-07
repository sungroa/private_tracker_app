import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';
import 'package:private_tracker_app/data/repositories/symptom_log_repository_impl.dart';
import 'package:private_tracker_app/data/storage/data_sources/symptom_data_source.dart';

class MockSymptomDataSource extends Mock implements SymptomDataSource {}

void main() {
  late MockSymptomDataSource mockDataSource;
  late SymptomLogRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(SymptomLog(
      date: DateTime.now(),
      symptoms: [],
      moodRating: 3,
    ));
  });

  setUp(() {
    mockDataSource = MockSymptomDataSource();
    repository = SymptomLogRepositoryImpl(mockDataSource);
  });

  tearDown(() {
    // Reset any global mocks if necessary
  });

  group('SymptomLogRepositoryImpl', () {
    test('getSymptomLogs returns logs from storage', () {
      final log = SymptomLog(date: DateTime.now(), symptoms: [], moodRating: 3);
      when(() => mockDataSource.getAllSymptomLogs()).thenReturn([log]);

      final result = repository.getSymptomLogs();

      expect(result.length, 1);
      expect(result.first, log);
      verify(() => mockDataSource.getAllSymptomLogs()).called(1);
    });

    test('getSymptomLogsForMonth calls storage', () {
      final month = DateTime(2023, 10);
      when(() => mockDataSource.getSymptomLogsForMonth(any())).thenReturn([]);

      repository.getSymptomLogsForMonth(month);

      verify(() => mockDataSource.getSymptomLogsForMonth(month)).called(1);
    });

    test('addSymptomLog calls storage save', () async {
      final log = SymptomLog(date: DateTime.now(), symptoms: [], moodRating: 3);
      when(() => mockDataSource.saveSymptomLog(any())).thenAnswer((_) async {});

      await repository.addSymptomLog(log);

      verify(() => mockDataSource.saveSymptomLog(log)).called(1);
    });

    test('updateSymptomLog calls storage save', () async {
      final log = SymptomLog(date: DateTime.now(), symptoms: [], moodRating: 3);
      when(() => mockDataSource.saveSymptomLog(any())).thenAnswer((_) async {});

      await repository.updateSymptomLog(log);

      verify(() => mockDataSource.saveSymptomLog(log)).called(1);
    });

    test('deleteSymptomLog calls storage delete', () async {
      const id = 'test-symptom-id';
      when(() => mockDataSource.deleteSymptomLog(any())).thenAnswer((_) async {});

      await repository.deleteSymptomLog(id);

      verify(() => mockDataSource.deleteSymptomLog(id)).called(1);
    });
  });
}
