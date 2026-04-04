import 'package:flutter/foundation.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/repositories/cycle_log_repository.dart';

class CycleProvider extends ChangeNotifier {
  final CycleLogRepository _repository;
  List<CycleLog> _cycleLogs = [];

  CycleProvider(this._repository) {
    _loadLogs();
  }

  List<CycleLog> get cycleLogs => _cycleLogs;

  void _loadLogs() {
    _cycleLogs = _repository.getCycleLogs();
    notifyListeners();
  }

  Future<void> addLog(CycleLog log) async {
    await _repository.addCycleLog(log);
    _loadLogs();
  }

  Future<void> updateLog(CycleLog log) async {
    await _repository.updateCycleEvent(log);
    _loadLogs();
  }

  Future<void> deleteLog(String id) async {
    await _repository.deleteCycleEvent(id);
    _loadLogs();
  }
}
