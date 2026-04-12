import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreferencesService {
  static const String _biometricEnabledKey = 'is_biometric_enabled';
  static const String _notificationsEnabledKey = 'is_notifications_enabled';
  static const String _notificationTimeKey = 'notification_time';
  static const String _cloudSyncEnabledKey = 'is_cloud_sync_enabled';
  static const String _lastSyncTimeKey = 'last_sync_time';

  final FlutterSecureStorage _secureStorage;

  PreferencesService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // For testing
  PreferencesService.test(this._secureStorage);

  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> isNotificationsEnabled() async {
    final value = await _secureStorage.read(key: _notificationsEnabledKey);
    return value == 'true';
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _secureStorage.write(key: _notificationsEnabledKey, value: enabled.toString());
  }

  Future<TimeOfDay> getNotificationTime() async {
    final value = await _secureStorage.read(key: _notificationTimeKey);
    if (value != null) {
      final parts = value.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 20,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    return const TimeOfDay(hour: 20, minute: 0);
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    final value = '${time.hour}:${time.minute}';
    await _secureStorage.write(key: _notificationTimeKey, value: value);
  }

  Future<bool> isCloudSyncEnabled() async {
    final value = await _secureStorage.read(key: _cloudSyncEnabledKey);
    return value == 'true';
  }

  Future<void> setCloudSyncEnabled(bool enabled) async {
    await _secureStorage.write(key: _cloudSyncEnabledKey, value: enabled.toString());
  }

  Future<DateTime?> getLastSyncTime() async {
    final value = await _secureStorage.read(key: _lastSyncTimeKey);
    if (value != null) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    await _secureStorage.write(key: _lastSyncTimeKey, value: time.toIso8601String());
  }
}
