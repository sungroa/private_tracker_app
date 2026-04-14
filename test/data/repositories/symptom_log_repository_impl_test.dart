import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/data/repositories/symptom_log_repository_impl.dart';
import 'package:private_tracker_app/data/storage/data_sources/symptom_data_source.dart';
import '../../helpers/test_model_factory.dart';

class MockSymptomDataSource extends Mock implements SymptomDataSource {}

void main() {
  late MockSymptomDataSource mockDataSource;
  late SymptomLogRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(TestModelFactory.createSymptomLog());
  });

  setUp(() {
    mockDataSource = MockSymptomDataSource();
    repository = SymptomLogRepositoryImpl(mockDataSource);
  });

  group('SymptomLogRepositoryImpl', () {
    test('getSymptomLogs returns logs from storage', () async {
      final log = TestModelFactory.createSymptomLog();
      when(() => mockDataSource.getSymptomLogs()).thenAnswer((_) async => [log]);

      final result = await repository.getSymptomLogs();

      expect(result.length, 1);
      expect(result.first, log);
      verify(() => mockDataSource.getSymptomLogs()).called(1);
    });

    test('getSymptomLogsForMonth calls storage', () async {
      final month = DateTime(2023, 10);
      when(() => mockDataSource.getSymptomLogsForMonth(any())).thenAnswer((_) async => []);

      await repository.getSymptomLogsForMonth(month);

      verify(() => mockDataSource.getSymptomLogsForMonth(month)).called(1);
    });

    test('addSymptomLog calls storage save', () async {
      final log = TestModelFactory.createSymptomLog();
      when(() => mockDataSource.saveSymptomLog(any())).thenAnswer((_) async {});

      await repository.addSymptomLog(log);

      verify(() => mockDataSource.saveSymptomLog(log)).called(1);
    });

    test('updateSymptomLog calls storage save', () async {
      final log = TestModelFactory.createSymptomLog();
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
