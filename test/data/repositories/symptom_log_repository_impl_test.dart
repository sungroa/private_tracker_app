import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/data/repositories/symptom_log_repository_impl.dart';
import 'package:private_tracker_app/data/storage/encrypted_storage_service.dart';

class MockEncryptedStorageService extends Mock implements EncryptedStorageService {}

void main() {
  late MockEncryptedStorageService mockStorageService;
  late SymptomLogRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(SymptomLog(
      date: DateTime.now(),
      symptoms: [],
      moodRating: 3,
    ));
  });

  setUp(() {
    mockStorageService = MockEncryptedStorageService();
    EncryptedStorageService.instance = mockStorageService;
    repository = SymptomLogRepositoryImpl(mockStorageService);
  });

  tearDown(() {
    EncryptedStorageService.resetForTesting();
  });

  group('SymptomLogRepositoryImpl', () {
    test('getSymptomLogs returns logs from storage', () {
      final log = SymptomLog(date: DateTime.now(), symptoms: [], moodRating: 3);
      when(() => mockStorageService.getSymptomLogs()).thenReturn([log]);

      final result = repository.getSymptomLogs();

      expect(result.length, 1);
      expect(result.first, log);
      verify(() => mockStorageService.getSymptomLogs()).called(1);
    });

    test('getSymptomLogsForMonth calls storage', () {
      final month = DateTime(2023, 10);
      when(() => mockStorageService.getSymptomLogsForMonth(any())).thenReturn([]);

      repository.getSymptomLogsForMonth(month);

      verify(() => mockStorageService.getSymptomLogsForMonth(month)).called(1);
    });

    test('addSymptomLog calls storage save', () async {
      final log = SymptomLog(date: DateTime.now(), symptoms: [], moodRating: 3);
      when(() => mockStorageService.saveSymptomLog(any())).thenAnswer((_) async {});

      await repository.addSymptomLog(log);

      verify(() => mockStorageService.saveSymptomLog(log)).called(1);
    });

    test('updateSymptomLog calls storage save', () async {
      final log = SymptomLog(date: DateTime.now(), symptoms: [], moodRating: 3);
      when(() => mockStorageService.saveSymptomLog(any())).thenAnswer((_) async {});

      await repository.updateSymptomLog(log);

      verify(() => mockStorageService.saveSymptomLog(log)).called(1);
    });

    test('deleteSymptomLog calls storage delete', () async {
      const id = 'test-symptom-id';
      when(() => mockStorageService.deleteSymptomLog(any())).thenAnswer((_) async {});

      await repository.deleteSymptomLog(id);

      verify(() => mockStorageService.deleteSymptomLog(id)).called(1);
    });
  });
}
