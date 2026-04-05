import 'package:hive/hive.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/symptom_log.dart';
import '../../domain/models/custom_tag.dart';

part 'hive_dtos.g.dart';

@HiveType(typeId: 10)
class CycleEventDto extends HiveObject {
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

  CycleEventDto({
    required this.id,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.flowIntensity,
  });

  factory CycleEventDto.fromDomain(CycleEvent domain) {
    return CycleEventDto(
      id: domain.id,
      startDate: domain.startDate,
      endDate: domain.endDate,
      notes: domain.notes,
      flowIntensity: domain.flowIntensity,
    );
  }

  CycleEvent sovereignty() {
    return CycleEvent(
      id: id,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
      flowIntensity: flowIntensity,
    );
  }
}

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

  SymptomLogDto({
    required this.id,
    required this.date,
    required this.symptoms,
    required this.moodRating,
    this.notes,
    this.basalBodyTemperature,
    this.cervicalFluidType,
    this.lhTestPositive,
  });

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
    );
  }

  SymptomLog sovereignty() {
    return SymptomLog(
      id: id,
      date: date,
      symptoms: symptoms,
      moodRating: moodRating,
      notes: notes,
      basalBodyTemperature: basalBodyTemperature,
      cervicalFluidType: cervicalFluidType,
      lhTestPositive: lhTestPositive,
    );
  }
}

@HiveType(typeId: 12)
class CustomTagDto extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final bool isDefault;

  CustomTagDto({
    required this.id,
    required this.name,
    required this.isDefault,
  });

  factory CustomTagDto.fromDomain(CustomTag domain) {
    return CustomTagDto(
      id: domain.id,
      name: domain.name,
      isDefault: domain.isDefault,
    );
  }

  CustomTag sovereignty() {
    return CustomTag(
      id: id,
      name: name,
      isDefault: isDefault,
    );
  }
}
