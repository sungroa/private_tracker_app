import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/core/services/auth_service.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late AuthService authService;
  late MockLocalAuthentication mockAuth;

  setUp(() {
    mockAuth = MockLocalAuthentication();
    authService = AuthService.test(mockAuth);
  });

  group('AuthService Tests', () {
    test('isHardwareSupported should return true if biometrics supported', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);

      final result = await authService.isHardwareSupported();
      expect(result, true);
    });

    test('authenticate should return true on success', () async {
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
          biometricOnly: any(named: 'biometricOnly'),
        ),
      ).thenAnswer((_) async => true);

      final result = await authService.authenticate();
      expect(result, true);

      verify(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          persistAcrossBackgrounding: false,
          biometricOnly: false,
        ),
      ).called(1);
    });

    test('authenticate should return true when LocalAuthException is noCredentialsSet', () async {
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
          biometricOnly: any(named: 'biometricOnly'),
        ),
      ).thenThrow(const LocalAuthException(code: LocalAuthExceptionCode.noCredentialsSet));

      final result = await authService.authenticate();
      expect(result, true);
    });

    test('authenticate should return false on other LocalAuthException', () async {
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
          biometricOnly: any(named: 'biometricOnly'),
        ),
      ).thenThrow(const LocalAuthException(code: LocalAuthExceptionCode.noBiometricsEnrolled));

      final result = await authService.authenticate();
      expect(result, false);
    });
  });
}
