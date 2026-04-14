import 'package:hive/hive.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/custom_tag.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';


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
  final DateTime updatedAt;

  CycleLogDto({
    required this.id,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.flowIntensity,
    required this.updatedAt,
  });
}

/// Data Transfer Object (DTO) for [SymptomLog].
@HiveType(typeId: 11)
class SymptomLogDto extends HiveObject {
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
  final DateTime updatedAt;

  SymptomLogDto({
    required this.id,
    required this.date,
    required this.symptoms,
    required this.moodRating,
    this.notes,
    this.basalBodyTemperature,
    this.cervicalFluidType,
    this.lhTestPositive,
    required this.updatedAt,
  });
}

/// Data Transfer Object (DTO) for [CustomTag].
@HiveType(typeId: 12)
class CustomTagDto extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final bool isDefault;
  @HiveField(3)
  final DateTime updatedAt;

  CustomTagDto({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.updatedAt,
  });
}
