import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/core/services/auth_service.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class FakeAuthenticationOptions extends Fake implements AuthenticationOptions {}

void main() {
  late AuthService authService;
  late MockLocalAuthentication mockAuth;
  late MockFlutterSecureStorage mockStorage;

  setUpAll(() {
    registerFallbackValue(FakeAuthenticationOptions());
  });

  setUp(() {
    mockAuth = MockLocalAuthentication();
    mockStorage = MockFlutterSecureStorage();
    authService = AuthService.test(mockAuth, mockStorage);
  });

  group('AuthService Tests', () {
    test('isHardwareSupported should return true if biometrics supported', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);

      final result = await authService.isHardwareSupported();
      expect(result, true);
    });

    test('isBiometricEnabled should return true if stored as true', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'true');

      final result = await authService.isBiometricEnabled();
      expect(result, true);
    });

    test('isBiometricEnabled should return false if stored as false or null', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'false');
      expect(await authService.isBiometricEnabled(), false);

      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      expect(await authService.isBiometricEnabled(), false);
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

      await authService.setBiometricEnabled(true);
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

    test('authenticate should return true on success', () async {
      when(() => mockAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => true);

      final result = await authService.authenticate();
      expect(result, true);
    });
  });
}
