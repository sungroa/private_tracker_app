import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/trends.dart';
import '../../domain/usecases/get_cycle_logs_use_case.dart';
import '../../domain/usecases/save_cycle_log_use_case.dart';
import '../../domain/usecases/delete_cycle_log_use_case.dart';
import '../../core/utils/security_logger.dart';
import '../../core/utils/date_time_extensions.dart';
import '../../core/services/notification_orchestrator.dart';
import 'cloud_sync_provider.dart';

/// State management provider for menstruation cycle data and predictions.
/// 
/// [CycleProvider] has been refactored to follow "Technical Excellence" principles:
/// 1. Zero constructor side-effects.
/// 2. Presentation-layer specific optimizations (calendar mapping).
/// 3. Async state handling with safety guards.
class CycleProvider extends ChangeNotifier {
  final GetCycleLogsUseCase _getCyclesUseCase;
  final SaveCycleLogUseCase _saveCycleUseCase;
  final DeleteCycleLogUseCase _deleteCycleUseCase;
  CloudSyncProvider? _cloudSync;
  NotificationOrchestrator? _notificationOrchestrator;
  
  /// The raw list of all cycle entries.
  List<CycleLog> _cycleEvents = [];

  /// Optimized lookup map for calendar rendering.
  /// (Presentation-only concern, moved from Domain).
  Map<String, CycleLog> _calendarEventMap = {};

  /// Aggregated trend and statistical data.
  TrendData? _trends;

  /// Global loading state.
  bool _isLoading = false;
  
  /// Error state tracking.
  String? _errorMessage;

  CycleProvider(
    this._getCyclesUseCase,
    this._saveCycleUseCase,
    this._deleteCycleUseCase, {
    CloudSyncProvider? cloudSync,
  }) : _cloudSync = cloudSync;

  /// Allows late binding of the sync provider to avoid circular dependency.
  void attachSyncProvider(CloudSyncProvider cloudSync) {
    _cloudSync = cloudSync;
  }

  /// Allows late binding of the notification orchestrator.
  void attachNotificationOrchestrator(NotificationOrchestrator orchestrator) {
    _notificationOrchestrator = orchestrator;
  }

  /// Explicit initialization to avoid constructor side-effects.
  Future<void> initialize() async {
    if (_cycleEvents.isNotEmpty || _isLoading) return;
    await _loadEvents();
  }

  void refresh() => _loadEvents();

  List<CycleLog> get cycleEvents => _cycleEvents;
  Map<String, CycleLog> get calendarEventMap => _calendarEventMap;
  TrendData? get trends => _trends;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// O(1) lookup to find a [CycleLog] for a specific day.
  CycleLog? getEventByDate(DateTime date) {
    return _calendarEventMap[date.toIsoDateString];
  }
  
  DateTime? get predictedNextPeriod => _trends?.predictedNextPeriod;
  List<DateTime> get predictedPeriodStarts => _trends?.predictedPeriodStarts ?? [];
  List<DateTime> get predictedFertilityDates => _trends?.predictedFertilityDates ?? [];

  /// Delegates bleeding prediction check to the domain model.
  bool isPredictedBleeding(DateTime date) => _trends?.isPredictedBleeding(date) ?? false;

  /// Delegates fertility prediction check to the domain model.
  bool isPredictedFertility(DateTime date) => _trends?.isPredictedFertility(date) ?? false;

  /// Loads and analyzes data via the [GetCycleLogsUseCase].
  Future<void> _loadEvents() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final analysis = await _getCyclesUseCase.execute();
      
      // Perform Presentation-only mapping in Background Isolate (W3)
      final map = await Isolate.run(() => _generateCalendarMapStatic(analysis.logs));
      
      // Atomic state update to prevent partial renders
      _cycleEvents = analysis.logs;
      _trends = analysis.trends;
      _calendarEventMap = map;
      
      _isLoading = false;
      notifyListeners();
      
      // Update prediction-based notifications
      unawaited(_notificationOrchestrator?.updateScheduledReminders(_trends) ?? Future.value());
    } catch (e, stack) {
      SecurityLogger.logError("CycleProvider.loadEvents", error: e, stackTrace: stack);
      _errorMessage = "Failed to load cycle data.";
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Static worker for [Isolate.run] to avoid capturing 'this'.
  static Map<String, CycleLog> _generateCalendarMapStatic(List<CycleLog> logs) {
    final Map<String, CycleLog> map = {};
    for (var event in logs) {
      final start = event.startDate.dateOnly;
      
      // Use recorded end date or a 4-day sensible default for UI projections
      final end = event.endDate?.dateOnly ?? start.add(const Duration(days: 4));
        
      var current = start;
      while (!current.isAfter(end)) {
        map[current.toIsoDateString] = event;
        current = current.add(const Duration(days: 1));
      }
    }
    return map;
  }

  /// Saves a new cycle log via [SaveCycleLogUseCase].
  Future<void> addEvent(CycleLog event) async {
    await _saveCycleUseCase.execute(event);
    await _loadEvents();
    _triggerSync();
  }

  /// Updates an existing cycle log via [SaveCycleLogUseCase].
  Future<void> updateEvent(CycleLog event) async {
    await _saveCycleUseCase.execute(event);
    await _loadEvents();
    _triggerSync();
  }

  /// Deletes a cycle log via [DeleteCycleLogUseCase].
  Future<void> deleteEvent(String id) async {
    await _deleteCycleUseCase.execute(id);
    await _loadEvents();
    _triggerSync();
  }

  /// Triggers a background sync without blocking the UI.
  ///
  /// Guards prevent sync from firing when a recovery passphrase is required
  /// ([requiresRecoveryPrompt]) or the local key cannot decrypt the cloud backup
  /// ([isOrphanKey]). Without these guards every data-write would trigger a
  /// CRITICAL FAILURE loop while the user hasn't entered their passphrase yet.
  void _triggerSync() {
    final sync = _cloudSync;
    if (sync != null &&
        sync.isCloudEnabled &&
        !sync.requiresRecoveryPrompt &&
        !sync.isOrphanKey) {
      unawaited(sync.sync());
    }
  }
}
