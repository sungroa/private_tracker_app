import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/repositories/symptom_log_repository.dart';
import 'package:private_tracker_app/presentation/providers/symptom_provider.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';


class MockSymptomLogRepository extends Mock implements SymptomLogRepository {}
class FakeSymptomLog extends Fake implements SymptomLog {}

void main() {
  late MockSymptomLogRepository mockRepo;
  late SymptomProvider provider;

  setUpAll(() {
    registerFallbackValue(FakeSymptomLog());
  });

  setUp(() {
    mockRepo = MockSymptomLogRepository();
    when(() => mockRepo.getSymptomLogs()).thenReturn([]);
    provider = SymptomProvider(mockRepo);
  });

  test('initial state loads logs', () {
    verify(() => mockRepo.getSymptomLogs()).called(1);
    expect(provider.symptomLogs, isEmpty);
  });

  test('addSymptomLog calls repository and reloads logs', () async {
    final log = SymptomLog(date: DateTime(2023, 1, 1), symptoms: const [], moodRating: 3);
    when(() => mockRepo.addSymptomLog(any())).thenAnswer((_) async {});
    when(() => mockRepo.getSymptomLogs()).thenReturn([log]);

    int listenerCallCount = 0;
    provider.addListener(() => listenerCallCount++);

    await provider.addSymptomLog(log);

    verify(() => mockRepo.addSymptomLog(log)).called(1);
    verify(() => mockRepo.getSymptomLogs()).called(2);
    expect(provider.symptomLogs, [log]);
    expect(listenerCallCount, 1);
  });

  test('updateSymptomLog calls repository and reloads logs', () async {
    final log = SymptomLog(date: DateTime(2023, 1, 1), symptoms: const [], moodRating: 3);
    when(() => mockRepo.updateSymptomLog(any())).thenAnswer((_) async {});
    when(() => mockRepo.getSymptomLogs()).thenReturn([log]);

    int listenerCallCount = 0;
    provider.addListener(() => listenerCallCount++);

    await provider.updateSymptomLog(log);

    verify(() => mockRepo.updateSymptomLog(log)).called(1);
    verify(() => mockRepo.getSymptomLogs()).called(2);
    expect(provider.symptomLogs, [log]);
    expect(listenerCallCount, 1);
  });

  test('deleteSymptomLog calls repository and reloads logs', () async {
    when(() => mockRepo.deleteSymptomLog(any())).thenAnswer((_) async {});
    
    int listenerCallCount = 0;
    provider.addListener(() => listenerCallCount++);

    await provider.deleteSymptomLog('test-id');

    verify(() => mockRepo.deleteSymptomLog('test-id')).called(1);
    verify(() => mockRepo.getSymptomLogs()).called(2);
    expect(listenerCallCount, 1);
  });
}
