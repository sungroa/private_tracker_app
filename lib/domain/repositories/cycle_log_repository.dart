import '../models/cycle_log.dart';

abstract class CycleLogRepository {
  List<CycleLog> getCycleLogs();
  Future<void> addCycleLog(CycleLog event);
  Future<void> updateCycleLog(CycleLog event);
  Future<void> deleteCycleLog(String id);
}
