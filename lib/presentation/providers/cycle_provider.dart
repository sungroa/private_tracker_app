import 'package:flutter/foundation.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/repositories/cycle_log_repository.dart';
import '../../domain/repositories/symptom_log_repository.dart';
import '../../domain/trends_calculator.dart';

class CycleProvider extends ChangeNotifier {
  final CycleLogRepository _repository;
  final SymptomLogRepository _symptomRepository;
  
  List<CycleEvent> _cycleEvents = [];
  Map<String, CycleEvent> _calendarEventMap = {};
  TrendData? _trends;
  DateTime? _predictedNextPeriod;
  List<DateTime> _predictedFertilityDates = [];

  CycleProvider(this._repository, this._symptomRepository) {
    _loadEvents();
  }

  void refresh() => _loadEvents();

  List<CycleEvent> get cycleEvents => _cycleEvents;
  Map<String, CycleEvent> get calendarEventMap => _calendarEventMap;
  TrendData? get trends => _trends;

  String _formatKey(DateTime date) => 
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  CycleEvent? getEventByDate(DateTime date) => _calendarEventMap[_formatKey(date)];
  DateTime? get predictedNextPeriod => _predictedNextPeriod;
  List<DateTime> get predictedFertilityDates => _predictedFertilityDates;

  void _loadEvents() {
    try {
      _cycleEvents = _repository.getCycleEvents();
      
      // Update indexed map for calendar lookups
      final Map<String, CycleEvent> newMap = {};
      for (var event in _cycleEvents) {
        final start = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
        final end = event.endDate != null 
          ? DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day)
          : start.add(const Duration(days: 4)); // Default visual length if ongoing/unspecified
          
        var current = start;
        while (!current.isAfter(end)) {
          newMap[_formatKey(current)] = event;
          current = current.add(const Duration(days: 1));
        }
      }
      _calendarEventMap = newMap;
      
      // Trigger calculation of trends and predictions
      final symptomLogs = _symptomRepository.getSymptomLogs();
      _trends = TrendsCalculator.calculateTrends(_cycleEvents, symptomLogs);
      
      _predictedNextPeriod = _trends?.predictedNextPeriod;
      _predictedFertilityDates = _trends?.predictedFertilityDates ?? [];
      
      notifyListeners();
    } catch (e) {
      debugPrint("CycleProvider: Failed to load events or calculate trends: $e");
      _cycleEvents = [];
      _calendarEventMap = {};
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
