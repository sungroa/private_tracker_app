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
  bool _isLoading = false;

  CycleProvider(this._repository, this._symptomRepository) {
    _loadEvents();
  }

  void refresh() => _loadEvents();

  List<CycleEvent> get cycleEvents => _cycleEvents;
  Map<String, CycleEvent> get calendarEventMap => _calendarEventMap;
  TrendData? get trends => _trends;
  bool get isLoading => _isLoading;

  String _formatKey(DateTime date) => 
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  CycleEvent? getEventByDate(DateTime date) => _calendarEventMap[_formatKey(date)];
  DateTime? get predictedNextPeriod => _predictedNextPeriod;
  List<DateTime> get predictedFertilityDates => _predictedFertilityDates;

  Future<void> _loadEvents() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final events = _repository.getCycleEvents();
      final symptomLogs = _symptomRepository.getSymptomLogs();
      
      // Build calendar map — O(events × days) work done eagerly
      final Map<String, CycleEvent> newMap = {};
      for (var event in events) {
        final start = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
        final end = event.endDate != null 
          ? DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day)
          : start.add(const Duration(days: 4));
          
        var current = start;
        while (!current.isAfter(end)) {
          newMap[_formatKey(current)] = event;
          current = current.add(const Duration(days: 1));
        }
      }

      // Calculate trends
      final trends = TrendsCalculator.calculateTrends(events, symptomLogs);
      
      // Commit state atomically
      _cycleEvents = events;
      _calendarEventMap = newMap;
      _trends = trends;
      _predictedNextPeriod = trends.predictedNextPeriod;
      _predictedFertilityDates = trends.predictedFertilityDates;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("CycleProvider: Failed to load events or calculate trends: $e");
      _cycleEvents = [];
      _calendarEventMap = {};
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEvent(CycleEvent event) async {
    await _repository.addCycleEvent(event);
    await _loadEvents();
  }

  Future<void> updateEvent(CycleEvent event) async {
    await _repository.updateCycleEvent(event);
    await _loadEvents();
  }

  Future<void> deleteEvent(String id) async {
    await _repository.deleteCycleEvent(id);
    await _loadEvents();
  }
}
