import 'package:flutter/foundation.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/repositories/cycle_log_repository.dart';
import '../../domain/repositories/symptom_log_repository.dart';
import '../../domain/trends_calculator.dart';

class CycleProvider extends ChangeNotifier {
  final CycleLogRepository _repository;
  final SymptomLogRepository _symptomRepository;
  
  List<CycleEvent> _cycleEvents = [];
  TrendData? _trends;
  DateTime? _predictedNextPeriod;
  List<DateTime> _predictedFertilityDates = [];

  CycleProvider(this._repository, this._symptomRepository) {
    _loadEvents();
  }

  void refresh() => _loadEvents();

  List<CycleEvent> get cycleEvents => _cycleEvents;
  TrendData? get trends => _trends;
  DateTime? get predictedNextPeriod => _predictedNextPeriod;
  List<DateTime> get predictedFertilityDates => _predictedFertilityDates;

  void _loadEvents() {
    try {
      _cycleEvents = _repository.getCycleEvents();
      
      // Trigger calculation of trends and predictions
      final symptomLogs = _symptomRepository.getSymptomLogs();
      _trends = TrendsCalculator.calculateTrends(_cycleEvents, symptomLogs);
      
      _predictedNextPeriod = _trends?.predictedNextPeriod;
      _predictedFertilityDates = _trends?.predictedFertilityDates ?? [];
      
      notifyListeners();
    } catch (e) {
      debugPrint("CycleProvider: Failed to load events or calculate trends: $e");
      _cycleEvents = [];
      notifyListeners();
    }
  }

  Future<void> addEvent(CycleEvent event) async {
    await _repository.addCycleEvent(event);
    _loadEvents();
  }

  Future<void> updateEvent(CycleEvent event) async {
    await _repository.updateCycleEvent(event);
    _loadEvents();
  }

  Future<void> deleteEvent(String id) async {
    await _repository.deleteCycleEvent(id);
    _loadEvents();
  }
}
