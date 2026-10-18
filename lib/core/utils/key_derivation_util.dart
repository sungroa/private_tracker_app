import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Utility for secure key derivation from a user-provided passphrase.
///
/// **Cryptographic Context**:
/// We use PBKDF2 (Password-Based Key Derivation Function 2) with HMAC-SHA256
/// rather than a direct hash (like pure SHA256) to mitigate brute-force and
/// rainbow-table attacks.
///
/// The `100,000` iteration count creates a deliberate CPU/memory bottleneck
/// during key derivation. This makes it computationally infeasible for an attacker
/// to guess the passphrase offline, while remaining fast enough (under 1 second)
/// for the user's occasional authentication on modern mobile devices.
///
/// The 16-byte random salt ensures that two users with the same passphrase
/// will produce completely different keys.
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
