import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/data/storage/hive_dtos.dart';

void main() {
  group('Hive Migration / Backward Compatibility Tests', () {
    test('CycleLogDto should handle null updatedAt (legacy data fallback)', () {
      final legacyDto = CycleLogDto(
        id: 'legacy-1',
        startDate: DateTime(2023, 1, 1),
        flowIntensity: 3,
        updatedAt: null, // Simulate missing field during deserialization
      );

      final domain = legacyDto.toDomain();

      expect(domain.id, equals('legacy-1'));
      expect(domain.updatedAt, equals(DateTime(1970)));
    });

    test('SymptomLogDto should handle null updatedAt (legacy data fallback)', () {
      final legacyDto = SymptomLogDto(
        id: 'legacy-2',
        date: DateTime(2023, 1, 1),
        symptoms: ['Cramps'],
        moodRating: 4,
        updatedAt: null, // Simulate missing field
      );

      final domain = legacyDto.toDomain();

      expect(domain.id, equals('legacy-2'));
      expect(domain.updatedAt, equals(DateTime(1970)));
    });

    test('CustomTagDto should handle null updatedAt (legacy data fallback)', () {
      final legacyDto = CustomTagDto(
        id: 'legacy-3',
        name: 'Exercise',
        isDefault: false,
        updatedAt: null, // Simulate missing field
      );

      final domain = legacyDto.toDomain();

      expect(domain.id, equals('legacy-3'));
      expect(domain.updatedAt, equals(DateTime(1970)));
    });
  });
}
