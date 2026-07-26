import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/usecases/get_symptom_logs_use_case.dart';
import '../../domain/usecases/save_symptom_log_use_case.dart';
import '../../domain/usecases/delete_symptom_log_use_case.dart';
import '../../domain/models/symptom_log.dart';
import '../../core/utils/date_time_extensions.dart';
import 'cloud_sync_provider.dart';

/// State management provider for health symptoms, moods, and FAM metrics.
/// 
/// 🎨 **Presentation Architecture**: This provider maintains the UI state for 
/// daily logs. It utilizes an indexed map ([_symptomMap]) to provide O(1) 
/// lookup for calendar rendering.
class SymptomProvider extends ChangeNotifier {
  final GetSymptomLogsUseCase _getUseCase;
  final SaveSymptomLogUseCase _saveUseCase;
  final DeleteSymptomLogUseCase _deleteUseCase;
  CloudSyncProvider? _cloudSync;
  
  List<SymptomLog> _symptomLogs = [];
  Map<String, SymptomLog> _symptomMap = {};
  bool _isLoading = false;

  SymptomProvider(this._getUseCase, this._saveUseCase, this._deleteUseCase, {
    this._cloudSync,
  });

  /// Allows late binding of the sync provider to avoid circular dependency.
  void attachSyncProvider(CloudSyncProvider cloudSync) {
    _cloudSync = cloudSync;
  }

  Future<void> initialize() async {
    if (_symptomLogs.isNotEmpty || _isLoading) return;
    await _loadLogs();
  }

  void refresh() => _loadLogs();

  List<SymptomLog> get symptomLogs => _symptomLogs;
  Map<String, SymptomLog> get symptomMap => _symptomMap;
  bool get isLoading => _isLoading;

  SymptomLog? getSymptomByDate(DateTime date) => _symptomMap[date.toIsoDateString];

  Future<void> _loadLogs() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      _symptomLogs = await _getUseCase.execute();
      
      // Update indexed map
      _symptomMap = {
        for (var log in _symptomLogs) log.date.toIsoDateString: log
      };
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("SymptomProvider: Failed to load logs: $e");
      _symptomLogs = [];
      _symptomMap = {};
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSymptomLog(SymptomLog log) async {
    await _saveUseCase.execute(log);
    await _loadLogs();
    _triggerSync();
  }

  Future<void> updateSymptomLog(SymptomLog log) async {
    await _saveUseCase.execute(log);
    await _loadLogs();
    _triggerSync();
  }

  Future<void> deleteSymptomLog(String id) async {
    await _deleteUseCase.execute(id);
    await _loadLogs();
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
