import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/data/storage/secure_key_storage.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SecureKeyStorage secureKeyStorage;
  late MockSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockSecureStorage();
    secureKeyStorage = SecureKeyStorage(mockStorage);
  });

  group('SecureKeyStorage Tests', () {
    test('getOrCreateEncryptionKey should return existing key if present', () async {
      final dummyKey = List<int>.generate(32, (i) => i);
      final encoded = base64UrlEncode(dummyKey);

      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => encoded);

      final key = await secureKeyStorage.getOrCreateEncryptionKey();

      expect(key, dummyKey);
      verify(() => mockStorage.read(key: any(named: 'key'))).called(1);
    });

    test('getOrCreateEncryptionKey should generate and save new key if absent', () async {
      final dummyKey = List<int>.generate(32, (i) => i);
      final encoded = base64UrlEncode(dummyKey);

      // First read returns null, then we write, then second read returns the key
      var callCount = 0;
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async {
        if (callCount++ == 0) return null;
        return encoded;
      });
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final key = await secureKeyStorage.getOrCreateEncryptionKey();

      expect(key, isA<List<int>>());
      expect(key.length, 32);
      verify(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).called(1);
    });

    test('getSupporterStatus returns true if value is "true"', () async {
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => 'true');
      final isSupporter = await secureKeyStorage.getSupporterStatus();
      expect(isSupporter, isTrue);
    });

    test('setSupporterStatus writes string value', () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      await secureKeyStorage.setSupporterStatus(true);
      verify(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: 'true',
        ),
      ).called(1);
    });
  });
}
