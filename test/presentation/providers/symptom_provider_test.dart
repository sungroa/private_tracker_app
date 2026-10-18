import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';
import 'package:private_tracker_app/domain/usecases/delete_symptom_log_use_case.dart';
import 'package:private_tracker_app/domain/usecases/get_symptom_logs_use_case.dart';
import 'package:private_tracker_app/domain/usecases/save_symptom_log_use_case.dart';
import 'package:private_tracker_app/presentation/providers/symptom_provider.dart';

class MockGetSymptomLogsUseCase extends Mock implements GetSymptomLogsUseCase {}

class MockSaveSymptomLogUseCase extends Mock implements SaveSymptomLogUseCase {}

class MockDeleteSymptomLogUseCase extends Mock implements DeleteSymptomLogUseCase {}

class FakeSymptomLog extends Fake implements SymptomLog {}

void main() {
  late MockGetSymptomLogsUseCase mockGetUseCase;
  late MockSaveSymptomLogUseCase mockSaveUseCase;
  late MockDeleteSymptomLogUseCase mockDeleteUseCase;
  late SymptomProvider provider;

  setUpAll(() {
    registerFallbackValue(FakeSymptomLog());
  });

  setUp(() {
    mockGetUseCase = MockGetSymptomLogsUseCase();
    mockSaveUseCase = MockSaveSymptomLogUseCase();
    mockDeleteUseCase = MockDeleteSymptomLogUseCase();

    when(() => mockGetUseCase.execute()).thenAnswer((_) async => []);
    provider = SymptomProvider(mockGetUseCase, mockSaveUseCase, mockDeleteUseCase);
  });

  test('constructor has zero side-effects', () {
    verifyNever(() => mockGetUseCase.execute());
    expect(provider.symptomLogs, isEmpty);
    expect(provider.isLoading, isFalse);
  });

  test('initialize loads logs via use case', () async {
    await provider.initialize();

    verify(() => mockGetUseCase.execute()).called(1);
    expect(provider.symptomLogs, isEmpty);
  });

  test('addSymptomLog calls use case and reloads logs', () async {
    final log = SymptomLog(
      id: 'test-id',
      date: DateTime(2023, 1, 1),
      symptoms: const [],
      moodRating: 3,
      updatedAt: DateTime.now(),
    );
    when(() => mockSaveUseCase.execute(any())).thenAnswer((_) async {});
    when(() => mockGetUseCase.execute()).thenAnswer((_) async => [log]);

    int listenerCallCount = 0;
    provider.addListener(() => listenerCallCount++);

    await provider.addSymptomLog(log);

    verify(() => mockSaveUseCase.execute(log)).called(1);
    verify(() => mockGetUseCase.execute()).called(1);
    expect(provider.symptomLogs, [log]);

    expect(listenerCallCount, 2);
  });

  test('updateSymptomLog calls use case and reloads logs', () async {
    final log = SymptomLog(
      id: 'test-id',
      date: DateTime(2023, 1, 1),
      symptoms: const [],
      moodRating: 3,
      updatedAt: DateTime.now(),
    );
    when(() => mockSaveUseCase.execute(any())).thenAnswer((_) async {});
    when(() => mockGetUseCase.execute()).thenAnswer((_) async => [log]);

    await provider.updateSymptomLog(log);

    verify(() => mockSaveUseCase.execute(log)).called(1);
    verify(() => mockGetUseCase.execute()).called(1);
    expect(provider.symptomLogs, [log]);
  });

  test('deleteSymptomLog calls use case and reloads logs', () async {
    when(() => mockDeleteUseCase.execute(any())).thenAnswer((_) async {});
    when(() => mockGetUseCase.execute()).thenAnswer((_) async => []);

    await provider.deleteSymptomLog('test-id');

    verify(() => mockDeleteUseCase.execute('test-id')).called(1);
    verify(() => mockGetUseCase.execute()).called(1);
  });
}
