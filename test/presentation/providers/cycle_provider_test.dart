import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/repositories/cycle_log_repository.dart';
import 'package:private_tracker_app/presentation/providers/cycle_provider.dart';

class MockCycleLogRepository extends Mock implements CycleLogRepository {}
class FakeCycleLog extends Fake implements CycleLog {}

void main() {
  late MockCycleLogRepository mockRepo;
  late CycleProvider provider;

  setUpAll(() {
    registerFallbackValue(FakeCycleLog());
  });

  setUp(() {
    mockRepo = MockCycleLogRepository();
    when(() => mockRepo.getCycleLogs()).thenReturn([]);
    provider = CycleProvider(mockRepo);
  });

  test('initial state loads logs', () {
    verify(() => mockRepo.getCycleLogs()).called(1);
    expect(provider.cycleLogs, isEmpty);
  });

  test('addLog calls repository and reloads logs', () async {
    final log = CycleLog(startDate: DateTime(2023, 1, 1));
    when(() => mockRepo.addCycleLog(any())).thenAnswer((_) async {});
    when(() => mockRepo.getCycleLogs()).thenReturn([log]);

    int listenerCallCount = 0;
    provider.addListener(() => listenerCallCount++);

    await provider.addLog(log);

    verify(() => mockRepo.addCycleLog(log)).called(1);
    verify(() => mockRepo.getCycleLogs()).called(2); // 1 initially, 1 after add
    expect(provider.cycleLogs, [log]);
    expect(listenerCallCount, 1);
  });

  test('updateLog calls repository and reloads logs', () async {
    final log = CycleLog(startDate: DateTime(2023, 1, 1));
    when(() => mockRepo.updateCycleEvent(any())).thenAnswer((_) async {});
    when(() => mockRepo.getCycleLogs()).thenReturn([log]);

    int listenerCallCount = 0;
    provider.addListener(() => listenerCallCount++);

    await provider.updateLog(log);

    verify(() => mockRepo.updateCycleEvent(log)).called(1);
    verify(() => mockRepo.getCycleLogs()).called(2);
    expect(provider.cycleLogs, [log]);
    expect(listenerCallCount, 1);
  });

  test('deleteLog calls repository and reloads logs', () async {
    when(() => mockRepo.deleteCycleEvent(any())).thenAnswer((_) async {});
    
    int listenerCallCount = 0;
    provider.addListener(() => listenerCallCount++);

    await provider.deleteLog('test-id');

    verify(() => mockRepo.deleteCycleEvent('test-id')).called(1);
    verify(() => mockRepo.getCycleLogs()).called(2);
    expect(listenerCallCount, 1);
  });
}
