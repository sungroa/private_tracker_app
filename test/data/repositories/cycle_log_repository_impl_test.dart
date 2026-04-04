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
    EncryptedStorageService.instance = mockStorageService;
    repository = CycleLogRepositoryImpl(mockStorageService);
    
    registerFallbackValue(CycleLog(startDate: DateTime.now()));
  });

  tearDown(() {
    EncryptedStorageService.resetForTesting();
  });

  group('CycleLogRepositoryImpl', () {
    test('getCycleLogs returns logs from storage', () {
      final log = CycleLog(startDate: DateTime.now());
      when(() => mockStorageService.getCycleLogs()).thenReturn([log]);

      final result = repository.getCycleLogs();

      expect(result.length, 1);
      expect(result.first, log);
      verify(() => mockStorageService.getCycleLogs()).called(1);
    });

    test('addCycleLog calls storage', () async {
      final log = CycleLog(startDate: DateTime.now());
      when(() => mockStorageService.saveCycleLog(any())).thenAnswer((_) async {});

      await repository.addCycleLog(log);

      verify(() => mockStorageService.saveCycleLog(log)).called(1);
    });

    test('updateCycleEvent calls storage save', () async {
      final log = CycleLog(startDate: DateTime.now());
      when(() => mockStorageService.saveCycleLog(any())).thenAnswer((_) async {});

      await repository.updateCycleEvent(log);

      verify(() => mockStorageService.saveCycleLog(log)).called(1);
    });

    test('deleteCycleEvent calls storage delete', () async {
      const id = 'test-id';
      when(() => mockStorageService.deleteCycleLog(any())).thenAnswer((_) async {});

      await repository.deleteCycleEvent(id);

      verify(() => mockStorageService.deleteCycleLog(id)).called(1);
    });
  });
}
