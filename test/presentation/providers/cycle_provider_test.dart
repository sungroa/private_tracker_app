import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/models/trends.dart';
import 'package:private_tracker_app/domain/usecases/get_cycle_logs_use_case.dart';
import 'package:private_tracker_app/domain/usecases/save_cycle_log_use_case.dart';
import 'package:private_tracker_app/domain/usecases/delete_cycle_log_use_case.dart';
import 'package:private_tracker_app/presentation/providers/cycle_provider.dart';

class MockGetCycleLogsUseCase extends Mock implements GetCycleLogsUseCase {}
class MockSaveCycleLogUseCase extends Mock implements SaveCycleLogUseCase {}
class MockDeleteCycleLogUseCase extends Mock implements DeleteCycleLogUseCase {}
class FakeCycleLog extends Fake implements CycleLog {}

void main() {
  late MockGetCycleLogsUseCase mockGetUseCase;
  late MockSaveCycleLogUseCase mockSaveUseCase;
  late MockDeleteCycleLogUseCase mockDeleteUseCase;
  late CycleProvider provider;

  setUpAll(() {
    registerFallbackValue(FakeCycleLog());
  });

  setUp(() {
    mockGetUseCase = MockGetCycleLogsUseCase();
    mockSaveUseCase = MockSaveCycleLogUseCase();
    mockDeleteUseCase = MockDeleteCycleLogUseCase();

    when(() => mockGetUseCase.execute()).thenAnswer((_) async => AnalysedCycles(
      logs: [],
      trends: TrendData(
        averageCycleLength: 0,
        averagePeriodDuration: 0,
        topSymptoms: [],
        moodHistory: [],
      ),
    ));

    provider = CycleProvider(mockGetUseCase, mockSaveUseCase, mockDeleteUseCase);
  });

  test('constructor has zero side-effects', () {
    verifyNever(() => mockGetUseCase.execute());
    expect(provider.isLoading, isFalse);
    expect(provider.cycleEvents, isEmpty);
  });

  test('initialize loads events via use case', () async {
    await provider.initialize();

    verify(() => mockGetUseCase.execute()).called(1);
    expect(provider.cycleEvents, isEmpty);
    expect(provider.predictedNextPeriod, isNull);
  });

  test('addEvent calls save use case and reloads', () async {
    final event = CycleLog(
      id: 'test-id',
      startDate: DateTime(2023, 1, 1),
      updatedAt: DateTime.now(),
    );
    when(() => mockSaveUseCase.execute(any())).thenAnswer((_) async {});
    
    when(() => mockGetUseCase.execute()).thenAnswer((_) async => AnalysedCycles(
      logs: [event],
      trends: TrendData(
        averageCycleLength: 0,
        averagePeriodDuration: 0,
        topSymptoms: [],
        moodHistory: [],
      ),
    ));

    int listenerCallCount = 0;
    provider.addListener(() => listenerCallCount++);

    await provider.addEvent(event);

    verify(() => mockSaveUseCase.execute(event)).called(1);
    verify(() => mockGetUseCase.execute()).called(1); 
    expect(provider.cycleEvents, [event]);
    
    expect(provider.getEventByDate(DateTime(2023, 1, 1)), event);
    expect(listenerCallCount, 2);
  });

  test('deleteEvent calls delete use case and reloads', () async {
    when(() => mockDeleteUseCase.execute(any())).thenAnswer((_) async {});
    when(() => mockGetUseCase.execute()).thenAnswer((_) async => AnalysedCycles(
      logs: [],
      trends: TrendData(averageCycleLength: 0, averagePeriodDuration: 0, topSymptoms: [], moodHistory: []),
    ));
    
    await provider.deleteEvent('test-id');

    verify(() => mockDeleteUseCase.execute('test-id')).called(1);
    verify(() => mockGetUseCase.execute()).called(1);
  });
}
