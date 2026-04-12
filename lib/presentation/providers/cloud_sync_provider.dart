import 'package:flutter/material.dart';
import '../../domain/services/cloud_sync_coordinator.dart';
import '../../core/services/preferences_service.dart';

class CloudSyncProvider with ChangeNotifier {
  final CloudSyncCoordinator _coordinator;
  final PreferencesService _prefs;

  bool _isSyncing = false;
  bool _isGoogleDriveEnabled = false;
  bool _isiCloudEnabled = false;
  String? _lastError;
  DateTime? _lastSyncTime;

  CloudSyncProvider({
    required CloudSyncCoordinator coordinator,
    required PreferencesService prefs,
  }) : _coordinator = coordinator,
       _prefs = prefs {
    _loadState();
  }

  bool get isSyncing => _isSyncing;
  bool get isGoogleDriveEnabled => _isGoogleDriveEnabled;
  bool get isiCloudEnabled => _isiCloudEnabled;
  bool get isCloudEnabled => _isGoogleDriveEnabled || _isiCloudEnabled;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;

  Future<void> _loadState() async {
    _isGoogleDriveEnabled = await _prefs.isCloudSyncEnabled();
    _lastSyncTime = await _prefs.getLastSyncTime();
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
    if (_isSyncing || !isCloudEnabled) return;

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      await _coordinator.sync();
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
