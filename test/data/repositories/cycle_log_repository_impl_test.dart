import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/data/repositories/cycle_log_repository_impl.dart';
import 'package:private_tracker_app/data/storage/data_sources/cycle_data_source.dart';
import '../../helpers/test_model_factory.dart';

class MockCycleDataSource extends Mock implements CycleDataSource {}

void main() {
  late MockCycleDataSource mockDataSource;
  late CycleLogRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(TestModelFactory.createCycleLog());
  });

  setUp(() {
    mockDataSource = MockCycleDataSource();
    repository = CycleLogRepositoryImpl(mockDataSource);
  });

  group('CycleLogRepositoryImpl', () {
    test('getCycleLogs returns events from storage', () async {
      final event = TestModelFactory.createCycleLog();
      when(() => mockDataSource.getCycleLogs()).thenAnswer((_) async => [event]);

      final result = await repository.getCycleLogs();

      expect(result.length, 1);
      expect(result.first, event);
      verify(() => mockDataSource.getCycleLogs()).called(1);
    });

    test('addCycleLog calls storage', () async {
      final event = TestModelFactory.createCycleLog();
      when(() => mockDataSource.saveCycleLog(any())).thenAnswer((_) async {});

      await repository.addCycleLog(event);

      verify(() => mockDataSource.saveCycleLog(event)).called(1);
    });

    test('updateCycleLog calls storage save', () async {
      final event = TestModelFactory.createCycleLog();
      when(() => mockDataSource.saveCycleLog(any())).thenAnswer((_) async {});

      await repository.updateCycleLog(event);

      verify(() => mockDataSource.saveCycleLog(event)).called(1);
    });

    test('deleteCycleLog calls storage delete', () async {
      const id = 'test-id';
      when(() => mockDataSource.deleteCycleLog(any())).thenAnswer((_) async {});

      await repository.deleteCycleLog(id);

      verify(() => mockDataSource.deleteCycleLog(id)).called(1);
    });
  });
}
