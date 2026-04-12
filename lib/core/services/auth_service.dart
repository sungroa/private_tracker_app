import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class AuthService {
  final LocalAuthentication _auth;

  AuthService({
    LocalAuthentication? auth,
  })  : _auth = auth ?? LocalAuthentication();

  // For testing
  AuthService.test(this._auth);

  /// Checks if device has biometric hardware support.
  Future<bool> isHardwareSupported() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
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
