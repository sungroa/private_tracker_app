import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/data/repositories/cycle_log_repository_impl.dart';
import 'package:private_tracker_app/data/storage/data_sources/cycle_data_source.dart';

class MockCycleDataSource extends Mock implements CycleDataSource {}

void main() {
  late MockCycleDataSource mockDataSource;
  late CycleLogRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockCycleDataSource();
    repository = CycleLogRepositoryImpl(mockDataSource);
    
    registerFallbackValue(CycleLog(startDate: DateTime.now()));
  });

  tearDown(() {
    // No global state to reset
  });

  group('CycleLogRepositoryImpl', () {
    test('getCycleLogs returns events from storage', () {
      final event = CycleLog(startDate: DateTime.now());
      when(() => mockDataSource.getCycleLogs()).thenReturn([event]);

      final result = repository.getCycleLogs();

      expect(result.length, 1);
      expect(result.first, event);
      verify(() => mockDataSource.getCycleLogs()).called(1);
    });

    test('addCycleLog calls storage', () async {
      final event = CycleLog(startDate: DateTime.now());
      when(() => mockDataSource.saveCycleLog(any())).thenAnswer((_) async {});

      await repository.addCycleLog(event);

      verify(() => mockDataSource.saveCycleLog(event)).called(1);
    });

    test('updateCycleLog calls storage save', () async {
      final event = CycleLog(startDate: DateTime.now());
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
