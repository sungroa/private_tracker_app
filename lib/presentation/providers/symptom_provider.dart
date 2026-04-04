import 'package:flutter/foundation.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/repositories/symptom_log_repository.dart';

class SymptomProvider extends ChangeNotifier {
  final SymptomLogRepository _repository;
  List<SymptomLog> _symptomLogs = [];

  SymptomProvider(this._repository) {
    _loadLogs();
  }

  List<SymptomLog> get symptomLogs => _symptomLogs;

  void _loadLogs() {
    _symptomLogs = _repository.getSymptomLogs();
    notifyListeners();
  }

  Future<void> addLog(SymptomLog log) async {
    await _repository.addSymptomLog(log);
    _loadLogs();
  }

  Future<void> updateLog(SymptomLog log) async {
    await _repository.updateSymptomEvent(log);
    _loadLogs();
  }

  Future<void> deleteLog(String id) async {
    await _repository.deleteSymptomEvent(id);
    _loadLogs();
  }
}
