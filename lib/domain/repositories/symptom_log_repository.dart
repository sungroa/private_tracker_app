import '../models/cycle_log.dart';

abstract class SymptomLogRepository {
  List<SymptomLog> getSymptomLogs();
  List<SymptomLog> getSymptomLogsForMonth(DateTime month);
  Future<void> addSymptomLog(SymptomLog log);
  Future<void> updateSymptomEvent(SymptomLog event);
  Future<void> deleteSymptomEvent(String id);
}
