import 'package:flutter/foundation.dart';
import '../../domain/repositories/symptom_log_repository.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';


class SymptomProvider extends ChangeNotifier {
  final SymptomLogRepository _repository;
  List<SymptomLog> _symptomLogs = [];
  Map<String, SymptomLog> _symptomMap = {};

  SymptomProvider(this._repository) {
    _loadLogs();
  }

  void refresh() => _loadLogs();

  List<SymptomLog> get symptomLogs => _symptomLogs;
  Map<String, SymptomLog> get symptomMap => _symptomMap;

  String _formatKey(DateTime date) => 
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  SymptomLog? getSymptomByDate(DateTime date) => _symptomMap[_formatKey(date)];

  void _loadLogs() {
    try {
      _symptomLogs = _repository.getSymptomLogs();
      
      // Update indexed map
      _symptomMap = {
        for (var log in _symptomLogs) _formatKey(log.date): log
      };
      
      notifyListeners();
    } catch (e) {
      debugPrint("SymptomProvider: Failed to load logs (storage likely not ready): $e");
      _symptomLogs = [];
      _symptomMap = {};
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
