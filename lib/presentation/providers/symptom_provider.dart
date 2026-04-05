import 'package:flutter/foundation.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/repositories/symptom_log_repository.dart';

class SymptomProvider extends ChangeNotifier {
  final SymptomLogRepository _repository;
  List<SymptomLog> _symptomLogs = [];

  SymptomProvider(this._repository) {
    _loadLogs();
  }

  void refresh() => _loadLogs();

  List<SymptomLog> get symptomLogs => _symptomLogs;

  void _loadLogs() {
    try {
      _symptomLogs = _repository.getSymptomLogs();
      notifyListeners();
    } catch (e) {
      debugPrint("SymptomProvider: Failed to load logs (storage likely not ready): $e");
      _symptomLogs = [];
      notifyListeners();
    }
  }

  Future<void> addSymptomLog(SymptomLog log) async {
    await _repository.addSymptomLog(log);
    _loadLogs();
  }

  Future<void> updateSymptomLog(SymptomLog log) async {
    await _repository.updateSymptomLog(log);
    _loadLogs();
  }

  Future<void> deleteSymptomLog(String id) async {
    await _repository.deleteSymptomLog(id);
    _loadLogs();
  }
}
