import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/repositories/cycle_log_repository.dart';
import 'package:private_tracker_app/domain/repositories/symptom_log_repository.dart';
import 'package:private_tracker_app/presentation/providers/cycle_provider.dart';

class MockCycleLogRepository extends Mock implements CycleLogRepository {}
class MockSymptomLogRepository extends Mock implements SymptomLogRepository {}
class FakeCycleEvent extends Fake implements CycleEvent {}

void main() {
  late MockCycleLogRepository mockRepo;
  late MockSymptomLogRepository mockSymptomRepo;
  late CycleProvider provider;

  setUpAll(() {
    registerFallbackValue(FakeCycleEvent());
  });

  setUp(() {
    mockRepo = MockCycleLogRepository();
    mockSymptomRepo = MockSymptomLogRepository();
    when(() => mockRepo.getCycleEvents()).thenReturn([]);
    when(() => mockSymptomRepo.getSymptomLogs()).thenReturn([]);
    provider = CycleProvider(mockRepo, mockSymptomRepo);
  });

  test('initial state loads events and calculates trends', () {
    verify(() => mockRepo.getCycleEvents()).called(1);
    verify(() => mockSymptomRepo.getSymptomLogs()).called(1);
    expect(provider.cycleEvents, isEmpty);
    expect(provider.predictedNextPeriod, isNull);
  });

  test('addEvent calls repository and reloads events', () async {
    final event = CycleEvent(startDate: DateTime(2023, 1, 1));
    when(() => mockRepo.addCycleEvent(any())).thenAnswer((_) async {});
    when(() => mockRepo.getCycleEvents()).thenReturn([event]);

    int listenerCallCount = 0;
    provider.addListener(() => listenerCallCount++);

    await provider.addEvent(event);

    verify(() => mockRepo.addCycleEvent(event)).called(1);
    verify(() => mockRepo.getCycleEvents()).called(2); // 1 initially, 1 after add
    expect(provider.cycleEvents, [event]);
    expect(listenerCallCount, 1);
  });

  test('predictedNextPeriod shifts when past cycle is updated', () async {
    // Setup: 2 cycles, 28 days apart.
    // Cycle 2: Mar 29
    // Cycle 1: Mar 1
    // Initial prediction: Mar 29 + 28 days = Apr 26
    final cycle1Start = DateTime(2026, 3, 1);
    final cycle2Start = DateTime(2026, 3, 29);
    final event1 = CycleEvent(startDate: cycle1Start);
    final event2 = CycleEvent(startDate: cycle2Start);

    when(() => mockRepo.getCycleEvents()).thenReturn([event2, event1]);
    provider.refresh(); // Reload with these 2 events

    expect(provider.predictedNextPeriod, DateTime(2026, 3, 29).add(const Duration(days: 28)));

    // Update: Shift cycle 2 to Mar 32? No, let's shift cycle 1 to Feb 26 (increasing interval to 31 days)
    // Newest interval: 31 days. Weighted average of one interval is 31.
    // New prediction: Mar 29 + 31 days = Apr 29
    final shiftedEvent1 = CycleEvent(startDate: DateTime(2026, 2, 26));
    when(() => mockRepo.updateCycleEvent(any())).thenAnswer((_) async {});
    when(() => mockRepo.getCycleEvents()).thenReturn([event2, shiftedEvent1]);

    await provider.updateEvent(shiftedEvent1);

    expect(provider.predictedNextPeriod, DateTime(2026, 3, 29).add(const Duration(days: 31)));
  });

  test('deleteEvent calls repository and reloads events', () async {
    when(() => mockRepo.deleteCycleEvent(any())).thenAnswer((_) async {});
    
    int listenerCallCount = 0;
    provider.addListener(() => listenerCallCount++);

    await provider.deleteEvent('test-id');

    verify(() => mockRepo.deleteCycleEvent('test-id')).called(1);
    verify(() => mockRepo.getCycleEvents()).called(2);
    expect(listenerCallCount, 1);
  });
}
