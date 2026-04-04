import '../models/cycle_log.dart';

abstract class CycleLogRepository {
  List<CycleLog> getCycleLogs();
  Future<void> addCycleLog(CycleLog log);
  Future<void> updateCycleEvent(CycleLog event);
  Future<void> deleteCycleEvent(String id);
}
