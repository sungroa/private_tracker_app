import 'package:flutter/material.dart';
import '../../domain/usecases/sync_data_use_case.dart';
import '../../core/services/preferences_service.dart';

class CloudSyncProvider with ChangeNotifier {
  final SyncDataUseCase _syncUseCase;
  final PreferencesService _prefs;

  bool _isSyncing = false;
  bool _isInitialized = false;
  bool _isGoogleDriveEnabled = false;
  bool _isiCloudEnabled = false;
  String? _lastError;
  DateTime? _lastSyncTime;

  CloudSyncProvider({
    required SyncDataUseCase syncUseCase,
    required PreferencesService prefs,
  }) : _syncUseCase = syncUseCase,
       _prefs = prefs;

  bool get isSyncing => _isSyncing;
  bool get isInitialized => _isInitialized;
  bool get isGoogleDriveEnabled => _isGoogleDriveEnabled;
  bool get isiCloudEnabled => _isiCloudEnabled;
  bool get isCloudEnabled => (_isGoogleDriveEnabled || _isiCloudEnabled) && _isInitialized;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// (W2) Explicit initialization to avoid async work in constructor.
  Future<void> init() async {
    if (_isInitialized) return;
    _isGoogleDriveEnabled = await _prefs.isCloudSyncEnabled();
    _lastSyncTime = await _prefs.getLastSyncTime();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> toggleGoogleDrive(bool enabled) async {
    _isGoogleDriveEnabled = enabled;
    await _prefs.setCloudSyncEnabled(enabled);
    notifyListeners();
    
    if (enabled) {
      await sync();
    }
  }

  Future<void> toggleICloud(bool enabled) async {
    _isiCloudEnabled = enabled;
    notifyListeners();
    
    if (enabled) {
      await sync();
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  Future<void> sync() async {
    if (!_isInitialized) await init();
    if (_isSyncing || !isCloudEnabled) return;

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      await _syncUseCase.execute();
      final now = DateTime.now();
      _lastSyncTime = now;
      await _prefs.setLastSyncTime(now);
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
