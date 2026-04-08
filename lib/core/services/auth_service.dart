import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'; // Required for TimeOfDay and @visibleForTesting

class AuthService {
  static const String _biometricEnabledKey = 'is_biometric_enabled';
  static const String _notificationsEnabledKey = 'is_notifications_enabled';
  static const String _notificationTimeKey = 'notification_time';
  
  final LocalAuthentication _auth;
  final FlutterSecureStorage _secureStorage;

  // Singleton instance
  static AuthService _instance = AuthService._internal(
    LocalAuthentication(),
    const FlutterSecureStorage(),
  );

  static AuthService get instance => _instance;

  @visibleForTesting
  static set instance(AuthService mock) => _instance = mock;

  AuthService._internal(this._auth, this._secureStorage);

  // For testing
  AuthService.test(this._auth, this._secureStorage);

  /// Checks if device has biometric hardware support.
  Future<bool> isHardwareSupported() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  /// Checks if the user has enabled biometric authentication.
  Future<bool> isBiometricEnabled() async {
    final String? enabled = await _secureStorage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Sets the biometric preference.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Checks if notifications are enabled.
  Future<bool> isNotificationsEnabled() async {
    final String? enabled = await _secureStorage.read(key: _notificationsEnabledKey);
    return enabled == 'true';
  }

  /// Sets notification preference.
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _notificationsEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Gets the scheduled notification time. Default is 20:00.
  Future<TimeOfDay> getNotificationTime() async {
    final String? timeString = await _secureStorage.read(key: _notificationTimeKey);
    if (timeString == null) return const TimeOfDay(hour: 20, minute: 0);
    
    final parts = timeString.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 20, minute: 0);
    
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 20,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  /// Sets the scheduled notification time. Format: "HH:mm".
  Future<void> setNotificationTime(TimeOfDay time) async {
    final String timeString = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    await _secureStorage.write(
      key: _notificationTimeKey,
      value: timeString,
    );
  }

  /// Triggers the biometric authentication prompt.
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access your private data',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable') {
        // Handle security settings not being setup
      }
      return false;
    }
  }
}
