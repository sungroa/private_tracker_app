import 'package:encrypt/encrypt.dart';
import '../models/shared_phase_data.dart';
import '../cycle_calculator.dart';
import '../models/cycle_log.dart';

class PartnerSharingService {
  static const String scheme = 'ptapp';
  static const String host = 'share';

  /// Generates an encrypted payload and its corresponding decryption key.
  static Map<String, String> generateEncryptedPayload({
    required List<CycleEvent> cycleLogs,
    List<SymptomLog>? symptomLogs,
  }) {
    // 1. Calculate phase data
    final nextPeriod = CycleCalculator.predictNextPeriod(cycleLogs, symptomLogs);
    
    // Standard estimate: Ovulation is ~14 days before next period
    final predictedOvulation = nextPeriod.subtract(const Duration(days: 14));
    final windowStart = predictedOvulation.subtract(const Duration(days: 3));
    final windowEnd = predictedOvulation.add(const Duration(days: 1));

    final data = SharedPhaseData(
      nextPeriodDate: nextPeriod,
      fertilityWindowStart: windowStart,
      fertilityWindowEnd: windowEnd,
      generatedAt: DateTime.now(),
    );

    // 2. Encryption
    final key = Key.fromSecureRandom(32);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key));

    final encrypted = encrypter.encrypt(data.toJson(), iv: iv);
    
    // Payload format: base64(iv) + ":" + base64(ciphertext)
    final payload = '${iv.base64}:${encrypted.base64}';
    
    return {
      'data': payload,
      'key': key.base64,
    };
  }

  /// Convenience method to generate the full deep link in one go.
  static String generateShareableLink(List<CycleEvent> cycleLogs, List<SymptomLog>? symptomLogs) {
    final result = generateEncryptedPayload(cycleLogs: cycleLogs, symptomLogs: symptomLogs);
    return generateDeepLink(result['data']!, result['key']!);
  }

  /// Decrypts a payload using the provided key.
  static SharedPhaseData decryptPayload(String payload, String keyBase64) {
    try {
      final parts = payload.split(':');
      if (parts.length != 2) throw Exception('Invalid payload format');

      final iv = IV.fromBase64(parts[0]);
      final ciphertext = parts[1];
      final key = Key.fromBase64(keyBase64);
      final encrypter = Encrypter(AES(key));

      final decrypted = encrypter.decrypt64(ciphertext, iv: iv);
      return SharedPhaseData.fromJson(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Generates a deep link URI.
  static String generateDeepLink(String payload, String key) {
    final encodedData = Uri.encodeComponent(payload);
    final encodedKey = Uri.encodeComponent(key);
    return '$scheme://$host?data=$encodedData&key=$encodedKey';
  }

  /// Parses a deep link URI.
  static Map<String, String>? parseDeepLink(Uri uri) {
    if (uri.scheme != scheme || uri.host != host) return null;
    
    final data = uri.queryParameters['data'];
    final key = uri.queryParameters['key'];
    
    if (data == null || key == null) return null;
    
    return {
      'data': data,
      'key': key,
    };
  }
}
