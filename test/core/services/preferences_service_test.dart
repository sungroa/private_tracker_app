import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/core/services/preferences_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late PreferencesService preferencesService;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    preferencesService = PreferencesService.test(mockStorage);
  });

  group('PreferencesService Tests', () {
    test('isBiometricEnabled should return true if stored as true', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'true');

      final result = await preferencesService.isBiometricEnabled();
      expect(result, true);
    });

    test('isBiometricEnabled should return false if stored as false or null', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'false');
      expect(await preferencesService.isBiometricEnabled(), false);

      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      expect(await preferencesService.isBiometricEnabled(), false);
    });

    test('setBiometricEnabled should write to storage', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
            iOptions: any(named: 'iOptions'),
            aOptions: any(named: 'aOptions'),
            lOptions: any(named: 'lOptions'),
            wOptions: any(named: 'wOptions'),
            mOptions: any(named: 'mOptions'),
            webOptions: any(named: 'webOptions'),
          )).thenAnswer((_) async => {});

      await preferencesService.setBiometricEnabled(true);
      verify(() => mockStorage.write(
            key: 'is_biometric_enabled',
            value: 'true',
            iOptions: any(named: 'iOptions'),
            aOptions: any(named: 'aOptions'),
            lOptions: any(named: 'lOptions'),
            wOptions: any(named: 'wOptions'),
            mOptions: any(named: 'mOptions'),
            webOptions: any(named: 'webOptions'),
          )).called(1);
    });
    
    test('getNotificationTime should return default if null', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
          
      expect(await preferencesService.getNotificationTime(), const TimeOfDay(hour: 20, minute: 0));
    });
    
    test('getNotificationTime should return stored value', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => '15:45');
          
      expect(await preferencesService.getNotificationTime(), const TimeOfDay(hour: 15, minute: 45));
    });
    
    test('setNotificationTime should format to string and save', () async {
       when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
            iOptions: any(named: 'iOptions'),
            aOptions: any(named: 'aOptions'),
            lOptions: any(named: 'lOptions'),
            wOptions: any(named: 'wOptions'),
            mOptions: any(named: 'mOptions'),
            webOptions: any(named: 'webOptions'),
          )).thenAnswer((_) async => {});

      await preferencesService.setNotificationTime(const TimeOfDay(hour: 9, minute: 5));
      verify(() => mockStorage.write(
            key: 'notification_time',
            value: '9:5',
            iOptions: any(named: 'iOptions'),
            aOptions: any(named: 'aOptions'),
            lOptions: any(named: 'lOptions'),
            wOptions: any(named: 'wOptions'),
            mOptions: any(named: 'mOptions'),
            webOptions: any(named: 'webOptions'),
          )).called(1);
    });
  });
}
