import 'package:hive/hive.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';

import '../../domain/models/custom_tag.dart';
import '../../domain/models/cycle_log.dart';

part 'hive_dtos.g.dart';

/// Data Transfer Object (DTO) for [CycleLog].
///
/// DTOs serve as the storage-specific representation of our domain models.
/// This layer is necessary to:
/// 1. Decouple domain logic from Hive annotations.
/// 2. Provide a stable schema for persistence that can be versioned independently.
/// 3. Safely handle JSON/binary transformations without polluting business logic.
@HiveType(typeId: 10)
class CycleLogDto extends HiveObject {
  CycleLogDto({
    required this.id,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.flowIntensity,
    this.updatedAt,
  });

  /// Maps a pure domain [CycleLog] into a [CycleLogDto] for persistence.
  factory CycleLogDto.fromDomain(CycleLog domain) {
    return CycleLogDto(
      id: domain.id,
      startDate: domain.startDate,
      endDate: domain.endDate,
      notes: domain.notes,
      flowIntensity: domain.flowIntensity,
      updatedAt: domain.updatedAt,
    );
  }
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime startDate;
  @HiveField(2)
  final DateTime? endDate;
  @HiveField(3)
  final String? notes;
  @HiveField(4)
  final int flowIntensity;
  @HiveField(5)
  final DateTime? updatedAt;

  /// Maps this [CycleLogDto] back into a pure domain [CycleLog].
  CycleLog toDomain() {
    return CycleLog(
      id: id,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
      flowIntensity: flowIntensity,
      updatedAt: updatedAt ?? DateTime(1970),
    );
  }
}

/// Data Transfer Object (DTO) for [SymptomLog].
@HiveType(typeId: 11)
class SymptomLogDto extends HiveObject {
  SymptomLogDto({
    required this.id,
    required this.date,
    required this.symptoms,
    required this.moodRating,
    this.notes,
    this.basalBodyTemperature,
    this.cervicalFluidType,
    this.lhTestPositive,
    this.updatedAt,
  });

  /// Maps a pure domain [SymptomLog] into a [SymptomLogDto] for persistence.
  factory SymptomLogDto.fromDomain(SymptomLog domain) {
    return SymptomLogDto(
      id: domain.id,
      date: domain.date,
      symptoms: domain.symptoms,
      moodRating: domain.moodRating,
      notes: domain.notes,
      basalBodyTemperature: domain.basalBodyTemperature,
      cervicalFluidType: domain.cervicalFluidType,
      lhTestPositive: domain.lhTestPositive,
      updatedAt: domain.updatedAt,
    );
  }
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final List<String> symptoms;
  @HiveField(3)
  final int moodRating;
  @HiveField(4)
  final String? notes;
  @HiveField(5)
  final double? basalBodyTemperature;
  @HiveField(6)
  final String? cervicalFluidType;
  @HiveField(7)
  final bool? lhTestPositive;
  @HiveField(8)
  final DateTime? updatedAt;

  /// Maps this [SymptomLogDto] back into a pure domain [SymptomLog].
  SymptomLog toDomain() {
    return SymptomLog(
      id: id,
      date: date,
      symptoms: symptoms,
      moodRating: moodRating,
      notes: notes,
      basalBodyTemperature: basalBodyTemperature,
      cervicalFluidType: cervicalFluidType,
      lhTestPositive: lhTestPositive,
      updatedAt: updatedAt ?? DateTime(1970),
    );
  }
}

/// Data Transfer Object (DTO) for [CustomTag].
@HiveType(typeId: 12)
class CustomTagDto extends HiveObject {
  CustomTagDto({required this.id, required this.name, required this.isDefault, this.updatedAt});

  /// Maps a pure domain [CustomTag] into a [CustomTagDto] for persistence.
  factory CustomTagDto.fromDomain(CustomTag domain) {
    return CustomTagDto(
      id: domain.id,
      name: domain.name,
      isDefault: domain.isDefault,
      updatedAt: domain.updatedAt,
    );
  }
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final bool isDefault;
  @HiveField(3)
  final DateTime? updatedAt;

  /// Maps this [CustomTagDto] back into a pure domain [CustomTag].
  CustomTag toDomain() {
    return CustomTag(
      id: id,
      name: name,
      isDefault: isDefault,
      updatedAt: updatedAt ?? DateTime(1970),
    );
  }
}
