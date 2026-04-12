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

  setUpAll(() {
    registerFallbackValue(FakeAuthenticationOptions());
  });

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
      when(() => mockAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => true);

      final result = await authService.authenticate();
      expect(result, true);
    });
  });
}
