import '../models/cycle_log.dart';

abstract class CycleLogRepository {
  List<CycleEvent> getCycleEvents();
  Future<void> addCycleEvent(CycleEvent event);
  Future<void> updateCycleEvent(CycleEvent event);
  Future<void> deleteCycleEvent(String id);
}
