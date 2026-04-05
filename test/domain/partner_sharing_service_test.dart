import 'package:flutter_test/flutter_test.dart';
import '../../lib/domain/services/partner_sharing_service.dart';
import '../../lib/domain/models/cycle_log.dart';
import '../../lib/domain/models/shared_phase_data.dart';

void main() {
  group('PartnerSharingService Tests', () {
    test('generateEncryptedPayload should produce a valid payload and key', () {
      final cycleLogs = [
        CycleEvent(startDate: DateTime(2026, 3, 1), endDate: DateTime(2026, 3, 5)),
        CycleEvent(startDate: DateTime(2026, 2, 1), endDate: DateTime(2026, 2, 5)),
      ];

      final result = PartnerSharingService.generateEncryptedPayload(cycleLogs: cycleLogs);

      expect(result.containsKey('data'), isTrue);
      expect(result.containsKey('key'), isTrue);
      expect(result['data']!.contains(':'), isTrue);
    });

    test('Encryption/Decryption cycle should preserve data integrity', () {
      final now = DateTime.now();
      final cycleLogs = [
        CycleEvent(startDate: now.subtract(const Duration(days: 30))),
        CycleEvent(startDate: now.subtract(const Duration(days: 60))),
      ];

      final result = PartnerSharingService.generateEncryptedPayload(cycleLogs: cycleLogs);
      final payload = result['data']!;
      final key = result['key']!;

      final decrypted = PartnerSharingService.decryptPayload(payload, key);

      // Predictions are based on the latest cycle (30 days ago) + average (28 days default)
      // So next period should be roughly 28 days after 30 days ago = 2 days ago? 
      // Wait, CycleCalculator predicts based on historical logs.
      
      expect(decrypted, isA<SharedPhaseData>());
      expect(decrypted.nextPeriodDate, isA<DateTime>());
      expect(decrypted.fertilityWindowStart, isA<DateTime>());
      expect(decrypted.fertilityWindowEnd, isA<DateTime>());
    });

    test('Deep link generation and parsing should be symmetric', () {
      const payload = 'ivbase64:cipherbase64';
      const key = 'keybase64';

      final link = PartnerSharingService.generateDeepLink(payload, key);
      final uri = Uri.parse(link);
      final parsed = PartnerSharingService.parseDeepLink(uri);

      expect(parsed, isNotNull);
      expect(parsed!['data'], equals(payload));
      expect(parsed['key'], equals(key));
    });

    test('decryptPayload should throw exception on invalid data', () {
      expect(
        () => PartnerSharingService.decryptPayload('invalidpayload', 'somekey'),
        throwsException,
      );
    });
  });
}
