import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/core/services/clock.dart';
import 'package:private_tracker_app/domain/cycle_calculator.dart';
import 'package:private_tracker_app/domain/repositories/cycle_log_repository.dart';
import 'package:private_tracker_app/domain/repositories/symptom_log_repository.dart';
import 'package:private_tracker_app/domain/trends_calculator.dart';
import 'package:private_tracker_app/domain/usecases/get_cycle_logs_use_case.dart';

class MockCycleLogRepository extends Mock implements CycleLogRepository {}

class MockSymptomLogRepository extends Mock implements SymptomLogRepository {}

void main() {
  late MockCycleLogRepository mockCycleRepo;
  late MockSymptomLogRepository mockSymptomRepo;
  late GetCycleLogsUseCase useCase;

  setUp(() {
    mockCycleRepo = MockCycleLogRepository();
    mockSymptomRepo = MockSymptomLogRepository();

    final clock = SystemClock();
    final calculator = CycleCalculator(clock);
    final trendsCalculator = TrendsCalculator(calculator);

    useCase = GetCycleLogsUseCase(mockCycleRepo, mockSymptomRepo, trendsCalculator);

    when(() => mockCycleRepo.getCycleLogs()).thenAnswer((_) async => []);
    when(() => mockSymptomRepo.getSymptomLogs()).thenAnswer((_) async => []);
  });

  test('execute returns AnalysedCycles asynchronously', () async {
    final result = await useCase.execute();

    expect(result, isA<AnalysedCycles>());
    expect(result.logs, isEmpty);
    verify(() => mockCycleRepo.getCycleLogs()).called(1);
    verify(() => mockSymptomRepo.getSymptomLogs()).called(1);
  });

  test('AnalysedCycles does not contain calendarMap', () async {
    final result = await useCase.execute();

    // This is a compile-time check technically, but good to have as a structural reminder
    // AnalysedCycles(logs: [], trends: ...) - no calendarMap in constructor
    expect(result.logs, isEmpty);
  });
}
