import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/domain/services/partner_sharing_service.dart';
import 'package:private_tracker_app/domain/models/shared_phase_data.dart';
import 'package:private_tracker_app/domain/cycle_calculator.dart';
import 'package:private_tracker_app/core/services/clock.dart';
import '../helpers/test_model_factory.dart';

void main() {
  late PartnerSharingService service;

  setUp(() {
    final clock = SystemClock();
    final cycleCalculator = CycleCalculator(clock);
    service = PartnerSharingService(cycleCalculator, clock);
  });

  group('PartnerSharingService Tests', () {
    test('generateEncryptedPayload should produce a valid payload and key', () {
      final cycleLogs = [
        TestModelFactory.createCycleLog(startDate: DateTime(2026, 3, 1), endDate: DateTime(2026, 3, 5)),
        TestModelFactory.createCycleLog(startDate: DateTime(2026, 2, 1), endDate: DateTime(2026, 2, 5)),
      ];

      final result = service.generateEncryptedPayload(cycleLogs: cycleLogs);

      expect(result.containsKey('data'), isTrue);
      expect(result.containsKey('key'), isTrue);
      expect(result['data']!.contains(':'), isTrue);
    });

    test('Encryption/Decryption cycle should preserve data integrity', () {
      final now = DateTime.now();
      final cycleLogs = [
        TestModelFactory.createCycleLog(startDate: now.subtract(const Duration(days: 30))),
        TestModelFactory.createCycleLog(startDate: now.subtract(const Duration(days: 60))),
      ];

      final result = service.generateEncryptedPayload(cycleLogs: cycleLogs);
      final payload = result['data']!;
      final key = result['key']!;

      final decrypted = service.decryptPayload(payload, key);

      expect(decrypted, isA<SharedPhaseData>());
      expect(decrypted.nextPeriodDate, isA<DateTime>());
      expect(decrypted.fertilityWindowStart, isA<DateTime>());
      expect(decrypted.fertilityWindowEnd, isA<DateTime>());
    });

    test('Deep link generation and parsing should be symmetric', () {
      const payload = 'ivbase64:cipherbase64:hmacbase64';
      const key = 'keybase64:hmacbase64';

      final link = service.generateDeepLink(payload, key);
      final uri = Uri.parse(link);
      final parsed = service.parseDeepLink(uri);

      expect(parsed, isNotNull);
      expect(parsed!['data'], equals(payload));
      expect(parsed['key'], equals(key));
    });

    test('decryptPayload should throw exception on invalid data', () {
      expect(
        () => service.decryptPayload('invalidpayload', 'some:key'),
        throwsException,
      );
    });
  });
}
