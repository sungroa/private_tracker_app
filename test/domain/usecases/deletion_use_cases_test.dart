import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/repositories/cycle_log_repository.dart';
import 'package:private_tracker_app/domain/repositories/symptom_log_repository.dart';
import 'package:private_tracker_app/domain/usecases/delete_cycle_log_use_case.dart';
import 'package:private_tracker_app/domain/usecases/delete_symptom_log_use_case.dart';

class MockCycleLogRepository extends Mock implements CycleLogRepository {}

class MockSymptomLogRepository extends Mock implements SymptomLogRepository {}

void main() {
  late MockCycleLogRepository mockCycleRepo;
  late MockSymptomLogRepository mockSymptomRepo;
  late DeleteCycleLogUseCase deleteCycleLogUseCase;
  late DeleteSymptomLogUseCase deleteSymptomLogUseCase;

  setUp(() {
    mockCycleRepo = MockCycleLogRepository();
    mockSymptomRepo = MockSymptomLogRepository();
    deleteCycleLogUseCase = DeleteCycleLogUseCase(mockCycleRepo);
    deleteSymptomLogUseCase = DeleteSymptomLogUseCase(mockSymptomRepo);
  });

  group('DeleteCycleLogUseCase Tests', () {
    test('execute should call repository delete', () async {
      when(() => mockCycleRepo.deleteCycleLog(any())).thenAnswer((_) async {});
      await deleteCycleLogUseCase.execute('id123');
      verify(() => mockCycleRepo.deleteCycleLog('id123')).called(1);
    });
  });

  group('DeleteSymptomLogUseCase Tests', () {
    test('execute should call repository delete', () async {
      when(() => mockSymptomRepo.deleteSymptomLog(any())).thenAnswer((_) async {});
      await deleteSymptomLogUseCase.execute('id456');
      verify(() => mockSymptomRepo.deleteSymptomLog('id456')).called(1);
    });
  });
}
