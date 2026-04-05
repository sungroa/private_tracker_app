import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/data/repositories/cycle_log_repository_impl.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';

class MockEncryptedStorageService extends Mock implements EncryptedStorageService {}

void main() {
  late MockEncryptedStorageService mockStorageService;
  late CycleLogRepositoryImpl repository;

  setUp(() {
    mockStorageService = MockEncryptedStorageService();
    repository = CycleLogRepositoryImpl(mockStorageService);
    
    registerFallbackValue(CycleEvent(startDate: DateTime.now()));
  });

  tearDown(() {
    // No global state to reset
  });

  group('CycleLogRepositoryImpl', () {
    test('getCycleEvents returns events from storage', () {
      final event = CycleEvent(startDate: DateTime.now());
      when(() => mockStorageService.getCycleEvents()).thenReturn([event]);

      final result = repository.getCycleEvents();

      expect(result.length, 1);
      expect(result.first, event);
      verify(() => mockStorageService.getCycleEvents()).called(1);
    });

    test('addCycleEvent calls storage', () async {
      final event = CycleEvent(startDate: DateTime.now());
      when(() => mockStorageService.saveCycleEvent(any())).thenAnswer((_) async {});

      await repository.addCycleEvent(event);

      verify(() => mockStorageService.saveCycleEvent(event)).called(1);
    });

    test('updateCycleEvent calls storage save', () async {
      final event = CycleEvent(startDate: DateTime.now());
      when(() => mockStorageService.saveCycleEvent(any())).thenAnswer((_) async {});

      await repository.updateCycleEvent(event);

      verify(() => mockStorageService.saveCycleEvent(event)).called(1);
    });

    test('deleteCycleEvent calls storage delete', () async {
      const id = 'test-id';
      when(() => mockStorageService.deleteCycleEvent(any())).thenAnswer((_) async {});

      await repository.deleteCycleEvent(id);

      verify(() => mockStorageService.deleteCycleEvent(id)).called(1);
    });
  });
}
