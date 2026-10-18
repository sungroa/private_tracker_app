import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PreferencesService preferencesService;

  setUp(() {
    // Reset SharedPreferences to a clean state before each test.
    SharedPreferences.setMockInitialValues({});
    preferencesService = PreferencesService();
  });

  group('PreferencesService Tests', () {
    // --- Biometric ---

    test('isBiometricEnabled returns false when nothing is stored', () async {
      expect(await preferencesService.isBiometricEnabled(), false);
    });

    test('isBiometricEnabled returns true after setBiometricEnabled(true)', () async {
      await preferencesService.setBiometricEnabled(true);
      expect(await preferencesService.isBiometricEnabled(), true);
    });

    test('isBiometricEnabled returns false after setBiometricEnabled(false)', () async {
      await preferencesService.setBiometricEnabled(true);
      await preferencesService.setBiometricEnabled(false);
      expect(await preferencesService.isBiometricEnabled(), false);
    });

    // --- Notifications ---

    test('isNotificationsEnabled returns false when nothing is stored', () async {
      expect(await preferencesService.isNotificationsEnabled(), false);
    });

    test('isNotificationsEnabled returns true after setNotificationsEnabled(true)', () async {
      await preferencesService.setNotificationsEnabled(true);
      expect(await preferencesService.isNotificationsEnabled(), true);
    });

    // --- Notification Time ---

    test('getNotificationTime returns default 20:00 when nothing is stored', () async {
      expect(await preferencesService.getNotificationTime(), const TimeOfDay(hour: 20, minute: 0));
    });

    test('getNotificationTime returns stored value after setNotificationTime', () async {
      await preferencesService.setNotificationTime(const TimeOfDay(hour: 9, minute: 5));
      expect(await preferencesService.getNotificationTime(), const TimeOfDay(hour: 9, minute: 5));
    });

    // --- Cloud Sync ---

    test('isCloudSyncEnabled returns false when nothing is stored', () async {
      expect(await preferencesService.isCloudSyncEnabled(), false);
    });

    test('isCloudSyncEnabled returns true after setCloudSyncEnabled(true)', () async {
      await preferencesService.setCloudSyncEnabled(true);
      expect(await preferencesService.isCloudSyncEnabled(), true);
    });

    // --- Last Sync Time ---

    test('getLastSyncTime returns null when nothing is stored', () async {
      expect(await preferencesService.getLastSyncTime(), isNull);
    });

    test('getLastSyncTime round-trips a DateTime through setLastSyncTime', () async {
      final now = DateTime.utc(2026, 5, 10, 12, 0, 0);
      await preferencesService.setLastSyncTime(now);
      final stored = await preferencesService.getLastSyncTime();
      expect(stored, isNotNull);
      expect(stored!.toUtc(), now);
    });

    test('setLastSyncTime(null) removes the stored value', () async {
      await preferencesService.setLastSyncTime(DateTime.now());
      await preferencesService.setLastSyncTime(null);
      expect(await preferencesService.getLastSyncTime(), isNull);
    });

    // --- Recovery Passphrase ---

    test('isRecoveryPassphraseSet returns false when nothing is stored', () async {
      expect(await preferencesService.isRecoveryPassphraseSet(), false);
    });

    test('isRecoveryPassphraseSet returns true after setRecoveryPassphraseSet(true)', () async {
      await preferencesService.setRecoveryPassphraseSet(true);
      expect(await preferencesService.isRecoveryPassphraseSet(), true);
    });

    // --- Recovery Salt ---

    test('getRecoverySalt returns null when nothing is stored', () async {
      expect(await preferencesService.getRecoverySalt(), isNull);
    });

    test('getRecoverySalt returns stored value after setRecoverySalt', () async {
      await preferencesService.setRecoverySalt('abc123salt');
      expect(await preferencesService.getRecoverySalt(), 'abc123salt');
    });

    test('setRecoverySalt(null) removes the stored value', () async {
      await preferencesService.setRecoverySalt('abc123salt');
      await preferencesService.setRecoverySalt(null);
      expect(await preferencesService.getRecoverySalt(), isNull);
    });
  });
}
