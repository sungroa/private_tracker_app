import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/export.dart';

/// Utility for secure key derivation from a user-provided passphrase.
/// 
/// Uses PBKDF2-HMAC-SHA256 with 100,000 iterations for high security,
/// and handles 16-byte random salt generation.
class KeyDerivationUtil {
  static const int iterations = 100000;
  static const int keyLength = 32; // 256 bits
  static const int saltLength = 16;

  /// Derives a 256-bit key from a [passphrase] and [salt].
  static Uint8List deriveKey(String passphrase, Uint8List salt) {
    final Uint8List passphraseBytes = Uint8List.fromList(passphrase.codeUnits);
    
    final PBKDF2KeyDerivator derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    
    derivator.init(Pbkdf2Parameters(salt, iterations, keyLength));
    
    return derivator.process(passphraseBytes);
  }

  /// Generates a random 16-byte salt for key derivation.
  static Uint8List generateSalt() {
    final Random random = Random.secure();
    final Uint8List salt = Uint8List(saltLength);
    for (int i = 0; i < saltLength; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }
}
