import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../utils/security_logger.dart';

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
      SecurityLogger.logInfo("AuthService: Starting biometric authentication prompt...");
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access your private data',
        options: const AuthenticationOptions(
          stickyAuth: false, // (W10) Disabled for better compatibility on Android 12
          biometricOnly: false,
          useErrorDialogs: true, // (W10) Explicitly enable system error UI
        ),
      );
      SecurityLogger.logInfo("AuthService: Authentication request completed. Result: $didAuthenticate");
      return didAuthenticate;
    } on PlatformException catch (e) {
      SecurityLogger.logError("AuthService: PlatformException during authentication [${e.code}]", error: e);
      if (e.code == 'NotAvailable') {
        // (W10) Device has no security lock (PIN/Bio) configured. 
        // We treat this as "authenticated" since there is no challenge possible.
        SecurityLogger.logInfo("AuthService: No device security configured. Proceeding by default.");
        return true;
      }
      return false;
    } catch (e) {
      SecurityLogger.logError("AuthService: Unexpected error during authentication", error: e);
      return false;
    }
  }
}
