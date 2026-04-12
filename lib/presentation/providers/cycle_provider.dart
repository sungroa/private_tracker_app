import 'package:flutter/foundation.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/repositories/cycle_log_repository.dart';
import '../../domain/repositories/symptom_log_repository.dart';
import '../../domain/trends_calculator.dart';

/// State management provider for menstruation cycle data and predictions.
/// 
/// [CycleProvider] handles the orchestration of loading cycle logs,
/// calculating trends, and maintaining a high-performance calendar lookup map.
/// It uses [ChangeNotifier] to inform the UI of state updates.
class CycleProvider extends ChangeNotifier {
  final CycleLogRepository _repository;
  final SymptomLogRepository _symptomRepository;
  
  /// The raw list of all cycle entries.
  List<CycleLog> _cycleEvents = [];

  /// Optimized lookup map for calendar rendering.
  /// Keys are formatted as 'YYYY-MM-DD' for O(1) day-cell lookups.
  Map<String, CycleLog> _calendarEventMap = {};

  /// Aggregated trend and statistical data.
  TrendData? _trends;

  /// The estimated start date of the next menstruation.
  DateTime? _predictedNextPeriod;

  /// A list of calculated fertile days for the current cycle.
  List<DateTime> _predictedFertilityDates = [];

  /// Global loading state for data-fetching operations.
  bool _isLoading = false;

  /// Initialization constructor. Triggers an initial data load.
  CycleProvider(this._repository, this._symptomRepository) {
    _loadEvents();
  }

  /// Public method to force a data refresh from repositories.
  void refresh() => _loadEvents();

  List<CycleLog> get cycleEvents => _cycleEvents;
  Map<String, CycleLog> get calendarEventMap => _calendarEventMap;
  TrendData? get trends => _trends;
  bool get isLoading => _isLoading;

  /// Formats a [DateTime] into a standardized key for the [_calendarEventMap].
  String _formatKey(DateTime date) => 
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  /// O(1) lookup to find a [CycleLog] for a specific day.
  CycleLog? getEventByDate(DateTime date) => _calendarEventMap[_formatKey(date)];
  
  DateTime? get predictedNextPeriod => _predictedNextPeriod;
  List<DateTime> get predictedFertilityDates => _predictedFertilityDates;

  /// Determines if a specific [date] falls within a predicted bleeding window.
  bool isPredictedBleeding(DateTime date) {
    if (_predictedNextPeriod == null) return false;
    final dateOnly = DateTime(date.year, date.month, date.day);
    final start = DateTime(_predictedNextPeriod!.year, _predictedNextPeriod!.month, _predictedNextPeriod!.day);
    
    // Projections assume a 4-day standard window if not otherwise specified.
    final end = start.add(const Duration(days: 4));
    return (dateOnly.isAtSameMomentAs(start) || (dateOnly.isAfter(start) && dateOnly.isBefore(end.add(const Duration(days: 1)))));
  }

  /// Determines if a specific [date] falls within the predicted fertile window.
  bool isPredictedFertility(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _predictedFertilityDates.any((d) => 
      d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day);
  }

  /// Internal core logic for loading, mapping, and analyzing data.
  /// 
  /// This method performs potentially heavy computations (mapping & analysis).
  /// Updates are performed atomically to ensure the UI never sees a partial state.
  Future<void> _loadEvents() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final events = _repository.getCycleLogs();
      final symptomLogs = _symptomRepository.getSymptomLogs();
      
      // Build calendar map — O(events × duration) work done eagerly.
      // This ensures that widget rebuilds (which happen frequently during scrolling or selection)
      // perform only O(1) lookups instead of O(N) searches.
      final Map<String, CycleLog> newMap = {};
      for (var event in events) {
        final start = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
        
        // Use the recorded end date, or a 4-day default for unclosed active cycles.
        final end = event.endDate != null 
          ? DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day)
          : start.add(const Duration(days: 4));
          
        var current = start;
        while (!current.isAfter(end)) {
          newMap[_formatKey(current)] = event;
          current = current.add(const Duration(days: 1));
        }
      }

      // Calculate trends using the domain TrendsCalculator.
      final trends = TrendsCalculator.calculateTrends(events, symptomLogs);
      
      // Atomic Update: Commit multiple related state variables in one go.
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

  /// Saves a new cycle log and refreshes the local state.
  Future<void> addEvent(CycleLog event) async {
    await _repository.addCycleLog(event);
    await _loadEvents();
  }

  /// Updates an existing cycle log and refreshes the local state.
  Future<void> updateEvent(CycleLog event) async {
    await _repository.updateCycleLog(event);
    await _loadEvents();
  }

  /// Deletes a cycle log and refreshes the local state.
  Future<void> deleteEvent(String id) async {
    await _repository.deleteCycleLog(id);
    await _loadEvents();
  }
}
