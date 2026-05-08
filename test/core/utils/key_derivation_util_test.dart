import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/core/utils/key_derivation_util.dart';

void main() {
  group('KeyDerivationUtil', () {
    test('deriveKey should produce consistent output for same passphrase and salt', () {
      const passphrase = 'test-passphrase-123';
      final salt = Uint8List.fromList(List<int>.generate(16, (i) => i));

      final key1 = KeyDerivationUtil.deriveKey(passphrase, salt);
      final key2 = KeyDerivationUtil.deriveKey(passphrase, salt);

      expect(key1, equals(key2));
      expect(key1.length, equals(32)); // 256 bits
    });

    test('deriveKey should produce different output for different passphrases', () {
      final salt = Uint8List.fromList(List<int>.generate(16, (i) => i));

      final key1 = KeyDerivationUtil.deriveKey('pass1', salt);
      final key2 = KeyDerivationUtil.deriveKey('pass2', salt);

      expect(key1, isNot(equals(key2)));
    });

    test('deriveKey should produce different output for different salts', () {
      const passphrase = 'test-passphrase';
      final salt1 = Uint8List.fromList(List<int>.generate(16, (i) => i));
      final salt2 = Uint8List.fromList(List<int>.generate(16, (i) => i + 1));

      final key1 = KeyDerivationUtil.deriveKey(passphrase, salt1);
      final key2 = KeyDerivationUtil.deriveKey(passphrase, salt2);

      expect(key1, isNot(equals(key2)));
    });

    test('generateSalt should produce unique 16-byte salts', () {
      final salt1 = KeyDerivationUtil.generateSalt();
      final salt2 = KeyDerivationUtil.generateSalt();

      expect(salt1.length, equals(16));
      expect(salt2.length, equals(16));
      expect(salt1, isNot(equals(salt2)));
    });
  });
}
