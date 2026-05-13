import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/security_logger.dart';

class PreferencesService {
  static const String _biometricEnabledKey = 'is_biometric_enabled';
  static const String _notificationsEnabledKey = 'is_notifications_enabled';
  static const String _notificationTimeKey = 'notification_time';
  static const String _cloudSyncEnabledKey = 'is_cloud_sync_enabled';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _recoveryPassphraseSetKey = 'is_recovery_passphrase_set';
  static const String _recoverySaltKey = 'recovery_salt';
  
  static const String _periodReminderEnabledKey = 'is_period_reminder_enabled';
  static const String _periodReminderOffsetKey = 'period_reminder_offset';
  static const String _periodReminderTimeKey = 'period_reminder_time';
  static const String _fertilityReminderEnabledKey = 'is_fertility_reminder_enabled';
  static const String _fertilityReminderOffsetKey = 'fertility_reminder_offset';
  static const String _fertilityReminderTimeKey = 'fertility_reminder_time';

  PreferencesService();

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<String?> _safeRead(String key) async {
    try {
      final p = await _prefs;
      return p.getString(key);
    } catch (e) {
      SecurityLogger.logInfo("PreferencesService: Read failed for $key. ($e)");
      return null;
    }
  }

  Future<void> _safeWrite(String key, String value) async {
    try {
      final p = await _prefs;
      await p.setString(key, value);
    } catch (e, stack) {
      SecurityLogger.logError("PreferencesService: Failed to write $key", error: e, stackTrace: stack);
    }
  }

  Future<void> _safeDelete(String key) async {
    try {
      final p = await _prefs;
      await p.remove(key);
    } catch (e, stack) {
      SecurityLogger.logError("PreferencesService: Failed to delete $key", error: e, stackTrace: stack);
    }
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _safeRead(_biometricEnabledKey);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _safeWrite(_biometricEnabledKey, enabled.toString());
  }

  Future<bool> isNotificationsEnabled() async {
    final value = await _safeRead(_notificationsEnabledKey);
    return value == 'true';
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _safeWrite(_notificationsEnabledKey, enabled.toString());
  }

  Future<TimeOfDay> getNotificationTime() async {
    final value = await _safeRead(_notificationTimeKey);
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
    await _safeWrite(_notificationTimeKey, value);
  }

  Future<bool> isCloudSyncEnabled() async {
    final value = await _safeRead(_cloudSyncEnabledKey);
    return value == 'true';
  }

  Future<void> setCloudSyncEnabled(bool enabled) async {
    await _safeWrite(_cloudSyncEnabledKey, enabled.toString());
  }

  Future<DateTime?> getLastSyncTime() async {
    final value = await _safeRead(_lastSyncTimeKey);
    if (value != null) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> setLastSyncTime(DateTime? time) async {
    if (time == null) {
      await _safeDelete(_lastSyncTimeKey);
    } else {
      await _safeWrite(_lastSyncTimeKey, time.toIso8601String());
    }
  }

  Future<bool> isRecoveryPassphraseSet() async {
    final value = await _safeRead(_recoveryPassphraseSetKey);
    return value == 'true';
  }

  Future<void> setRecoveryPassphraseSet(bool set) async {
    await _safeWrite(_recoveryPassphraseSetKey, set.toString());
  }

  Future<String?> getRecoverySalt() async {
    return await _safeRead(_recoverySaltKey);
  }

  Future<void> setRecoverySalt(String? salt) async {
    if (salt == null) {
      await _safeDelete(_recoverySaltKey);
    } else {
      await _safeWrite(_recoverySaltKey, salt);
    }
  }
  
  // --- Period Reminder ---

  Future<bool> isPeriodReminderEnabled() async {
    final value = await _safeRead(_periodReminderEnabledKey);
    return value == 'true';
  }

  Future<void> setPeriodReminderEnabled(bool enabled) async {
    await _safeWrite(_periodReminderEnabledKey, enabled.toString());
  }

  Future<int> getPeriodReminderOffset() async {
    final value = await _safeRead(_periodReminderOffsetKey);
    return int.tryParse(value ?? '1') ?? 1;
  }

  Future<void> setPeriodReminderOffset(int offset) async {
    await _safeWrite(_periodReminderOffsetKey, offset.toString());
  }

  Future<TimeOfDay> getPeriodReminderTime() async {
    final value = await _safeRead(_periodReminderTimeKey);
    if (value != null) {
      final parts = value.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  Future<void> setPeriodReminderTime(TimeOfDay time) async {
    final value = '${time.hour}:${time.minute}';
    await _safeWrite(_periodReminderTimeKey, value);
  }

  // --- Fertility Reminder ---

  Future<bool> isFertilityReminderEnabled() async {
    final value = await _safeRead(_fertilityReminderEnabledKey);
    return value == 'true';
  }

  Future<void> setFertilityReminderEnabled(bool enabled) async {
    await _safeWrite(_fertilityReminderEnabledKey, enabled.toString());
  }

  Future<int> getFertilityReminderOffset() async {
    final value = await _safeRead(_fertilityReminderOffsetKey);
    return int.tryParse(value ?? '1') ?? 1;
  }

  Future<void> setFertilityReminderOffset(int offset) async {
    await _safeWrite(_fertilityReminderOffsetKey, offset.toString());
  }

  Future<TimeOfDay> getFertilityReminderTime() async {
    final value = await _safeRead(_fertilityReminderTimeKey);
    if (value != null) {
      final parts = value.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  Future<void> setFertilityReminderTime(TimeOfDay time) async {
    final value = '${time.hour}:${time.minute}';
    await _safeWrite(_fertilityReminderTimeKey, value);
  }
}
