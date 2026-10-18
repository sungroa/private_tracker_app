import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:private_tracker_app/domain/models/symptom_log.dart';

import '../../core/services/clock.dart';
import '../cycle_calculator.dart';
import '../models/cycle_log.dart';
import '../models/shared_phase_data.dart';

/// Service responsible for encrypting and decrypting data for partner sharing.
///
/// Refactored from static to instance methods to support dependency injection and testability.
class PartnerSharingService {
  PartnerSharingService(this._cycleCalculator, this._clock);
  static const String scheme = 'ptapp';
  static const String host = 'share';

  final CycleCalculator _cycleCalculator;
  final IClock _clock;

  /// Generates an encrypted payload and its corresponding decryption key.
  Map<String, String> generateEncryptedPayload({
    required List<CycleLog> cycleLogs,
    List<SymptomLog>? symptomLogs,
  }) {
    if (cycleLogs.isEmpty) {
      throw ArgumentError('Cannot generate partner payload: no cycle data recorded yet.');
    }

    // 1. Calculate phase data
    final nextPeriod = _cycleCalculator.predictNextPeriod(cycleLogs, symptomLogs);
    if (nextPeriod == null) {
      throw StateError('Cannot predict next period with current data.');
    }

    // Standard estimate: Ovulation is ~14 days before next period
    final predictedOvulation = nextPeriod.subtract(const Duration(days: 14));
    final windowStart = predictedOvulation.subtract(const Duration(days: 3));
    final windowEnd = predictedOvulation.add(const Duration(days: 1));

    final data = SharedPhaseData(
      nextPeriodDate: nextPeriod,
      fertilityWindowStart: windowStart,
      fertilityWindowEnd: windowEnd,
      generatedAt: _clock.now(),
    );

    // 2. Encryption
    final encryptionKey = enc.Key.fromSecureRandom(32);
    final hmacKey = enc.Key.fromSecureRandom(32);
    final iv = enc.IV.fromSecureRandom(16);

    // Use AES with SIC (CTR) mode
    final encrypter = enc.Encrypter(enc.AES(encryptionKey, mode: enc.AESMode.sic));
    final encrypted = encrypter.encrypt(data.toJson(), iv: iv);

    // 3. Authenticate (Encrypt-then-MAC)
    final hmac = Hmac(sha256, hmacKey.bytes);
    final digest = hmac.convert(iv.bytes + encrypted.bytes);

    // Payload format: base64(iv) + ":" + base64(ciphertext) + ":" + base64(hmac)
    final payload = '${iv.base64}:${encrypted.base64}:${base64UrlEncode(digest.bytes)}';

    // Key format: base64(encKey) + ":" + base64(hmacKey)
    final combinedKey = '${encryptionKey.base64}:${hmacKey.base64}';

    return {'data': payload, 'key': combinedKey};
  }

  /// Convenience method to generate the full deep link in one go.
  String generateShareableLink(List<CycleLog> cycleLogs, List<SymptomLog>? symptomLogs) {
    final result = generateEncryptedPayload(cycleLogs: cycleLogs, symptomLogs: symptomLogs);
    return generateDeepLink(result['data']!, result['key']!);
  }

  /// Decrypts a payload using the provided key.
  SharedPhaseData decryptPayload(String payload, String keyCombined) {
    try {
      final keyParts = keyCombined.split(':');
      if (keyParts.length != 2) throw Exception('Invalid key format');

      final encryptionKey = enc.Key.fromBase64(keyParts[0]);
      final hmacKey = enc.Key.fromBase64(keyParts[1]);

      final payloadParts = payload.split(':');
      if (payloadParts.length != 3) throw Exception('Invalid payload format');

      final iv = enc.IV.fromBase64(payloadParts[0]);
      final ciphertext = payloadParts[1];
      final hmacProvided = payloadParts[2];

      // 1. Verify HMAC (Constant-time comparison)
      final hmac = Hmac(sha256, hmacKey.bytes);
      final encryptedBytes = base64.decode(ciphertext);
      final digest = hmac.convert(iv.bytes + encryptedBytes);
      final hmacExpected = base64UrlEncode(digest.bytes);

      if (!_secureEquals(hmacProvided, hmacExpected)) {
        throw Exception('Authenticity check failed: Payload has been tampered with');
      }

      // 2. Decrypt
      final encrypter = enc.Encrypter(enc.AES(encryptionKey, mode: enc.AESMode.sic));
      final decrypted = encrypter.decrypt64(ciphertext, iv: iv);
      return SharedPhaseData.fromJson(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Generates a deep link URI.
  String generateDeepLink(String payload, String key) {
    final encodedData = Uri.encodeComponent(payload);
    final encodedKey = Uri.encodeComponent(key);
    return '$scheme://$host?data=$encodedData&key=$encodedKey';
  }

  /// Parses a deep link URI.
  Map<String, String>? parseDeepLink(Uri uri) {
    if (uri.scheme != scheme || uri.host != host) return null;

    final data = uri.queryParameters['data'];
    final key = uri.queryParameters['key'];

    if (data == null || key == null) return null;

    return {'data': data, 'key': key};
  }

  /// Constant-time comparison to prevent timing attacks.
  ///
  /// Fix C4: Ensures that even if lengths differ, we perform a deterministic amount of work
  /// (relative to the expected length) before returning.
  bool _secureEquals(String a, String b) {
    // We always compare against the expected length of 'b' (the known good value)
    if (b.isEmpty) return a.isEmpty;

    // In our case, 'b' is always a base64Url enc-HMAC (43 chars)
    // but we generalize to b.length.
    int result = 0;

    // If lengths differ, we still iterate through 'b' and XOR with a dummy char
    // to maintain a similar timing profile to a failed check on identical lengths.
    if (a.length != b.length) {
      result = 1;
      // Compare b with itself to stay busy for b.length time
      for (int i = 0; i < b.length; i++) {
        result |= b.codeUnitAt(i) ^ b.codeUnitAt(i);
      }
      return false;
    }

    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
