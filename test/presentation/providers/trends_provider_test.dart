import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/presentation/providers/cycle_provider.dart';
import 'package:private_tracker_app/presentation/providers/symptom_provider.dart';
import 'package:private_tracker_app/presentation/providers/trends_provider.dart';
import 'package:private_tracker_app/domain/repositories/cycle_log_repository.dart';
import 'package:private_tracker_app/domain/repositories/symptom_log_repository.dart';

class MockCycleLogRepository extends Mock implements CycleLogRepository {}
class MockSymptomLogRepository extends Mock implements SymptomLogRepository {}

void main() {
  late MockCycleLogRepository mockCycleRepo;
  late MockSymptomLogRepository mockSymptomRepo;
  late CycleProvider cycleProvider;
  late SymptomProvider symptomProvider;
  late TrendsProvider trendsProvider;

  setUp(() {
    mockCycleRepo = MockCycleLogRepository();
    when(() => mockCycleRepo.getCycleLogs()).thenReturn([]);
    
    mockSymptomRepo = MockSymptomLogRepository();
    when(() => mockSymptomRepo.getSymptomLogs()).thenReturn([]);

    cycleProvider = CycleProvider(mockCycleRepo);
    symptomProvider = SymptomProvider(mockSymptomRepo);
    
    trendsProvider = TrendsProvider();
  });

  test('update triggers calculation and notifies listeners', () {
    int listenerCallCount = 0;
    trendsProvider.addListener(() => listenerCallCount++);

    // Give it some data
    final log = CycleLog(startDate: DateTime(2023, 1, 1));
    when(() => mockCycleRepo.getCycleLogs()).thenReturn([log]);
    // Manually reload it within testing
    cycleProvider = CycleProvider(mockCycleRepo);

    trendsProvider.update(cycleProvider, symptomProvider);

    expect(trendsProvider.trendData, isNotNull);
    expect(trendsProvider.trendData!.averageCycleLength, equals(28.0)); // From default calculation length
    expect(listenerCallCount, 1);
  });
}
