import '../../domain/models/custom_tag.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/symptom_log.dart';
import 'hive_dtos.dart';

/// Static utility class to handle Domain <-> Map and Domain <-> DTO conversion.
/// 
/// This class lives in the Data layer to keep Domain models pure and
/// decoupled from serialization formats (like JSON/Map or Hive DTOs).
class ModelMapper {
  // --- CycleLog ---

  static Map<String, dynamic> cycleLogToMap(CycleLog domain) {
    return {
      'id': domain.id,
      'startDate': domain.startDate.toIso8601String(),
      'endDate': domain.endDate?.toIso8601String(),
      'notes': domain.notes,
      'flowIntensity': domain.flowIntensity,
      'updatedAt': domain.updatedAt.toUtc().toIso8601String(),
    };
  }

  static CycleLog cycleLogFromMap(Map<String, dynamic> map) {
    return CycleLog(
      id: map['id']?.toString() ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      notes: map['notes'],
      flowIntensity: map['flowIntensity'] ?? 3,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  static CycleLogDto cycleLogToDto(CycleLog domain) {
    return CycleLogDto(
      id: domain.id,
      startDate: domain.startDate,
      endDate: domain.endDate,
      notes: domain.notes,
      flowIntensity: domain.flowIntensity,
      updatedAt: domain.updatedAt,
    );
  }

  static CycleLog cycleLogFromDto(CycleLogDto dto) {
    return CycleLog(
      id: dto.id,
      startDate: dto.startDate,
      endDate: dto.endDate,
      notes: dto.notes,
      flowIntensity: dto.flowIntensity,
      updatedAt: dto.updatedAt ?? DateTime(1970),
    );
  }

  // --- SymptomLog ---

  static Map<String, dynamic> symptomLogToMap(SymptomLog domain) {
    return {
      'id': domain.id,
      'date': domain.date.toIso8601String(),
      'symptoms': domain.symptoms.toList(),
      'moodRating': domain.moodRating,
      'notes': domain.notes,
      'basalBodyTemperature': domain.basalBodyTemperature,
      'cervicalFluidType': domain.cervicalFluidType,
      'lhTestPositive': domain.lhTestPositive,
      'updatedAt': domain.updatedAt.toUtc().toIso8601String(),
    };
  }

  static SymptomLog symptomLogFromMap(Map<String, dynamic> map) {
    return SymptomLog(
      id: map['id']?.toString() ?? '',
      date: DateTime.parse(map['date']),
      symptoms: List<String>.from(map['symptoms']),
      moodRating: map['moodRating'] ?? 3,
      notes: map['notes'],
      basalBodyTemperature: map['basalBodyTemperature']?.toDouble(),
      cervicalFluidType: map['cervicalFluidType'],
      lhTestPositive: map['lhTestPositive'],
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  static SymptomLogDto symptomLogToDto(SymptomLog domain) {
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

  static SymptomLog symptomLogFromDto(SymptomLogDto dto) {
    return SymptomLog(
      id: dto.id,
      date: dto.date,
      symptoms: dto.symptoms,
      moodRating: dto.moodRating,
      notes: dto.notes,
      basalBodyTemperature: dto.basalBodyTemperature,
      cervicalFluidType: dto.cervicalFluidType,
      lhTestPositive: dto.lhTestPositive,
      updatedAt: dto.updatedAt ?? DateTime(1970),
    );
  }

  // --- CustomTag ---

  static Map<String, dynamic> customTagToMap(CustomTag domain) {
    return {
      'id': domain.id,
      'name': domain.name,
      'isDefault': domain.isDefault,
      'updatedAt': domain.updatedAt.toUtc().toIso8601String(),
    };
  }

  static CustomTag customTagFromMap(Map<String, dynamic> map) {
    return CustomTag(
      id: map['id']?.toString() ?? '',
      name: map['name'],
      isDefault: map['isDefault'] ?? false,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  static CustomTagDto customTagToDto(CustomTag domain) {
    return CustomTagDto(
      id: domain.id,
      name: domain.name,
      isDefault: domain.isDefault,
      updatedAt: domain.updatedAt,
    );
  }

  static CustomTag customTagFromDto(CustomTagDto dto) {
    return CustomTag(
      id: dto.id,
      name: dto.name,
      isDefault: dto.isDefault,
      updatedAt: dto.updatedAt ?? DateTime(1970),
    );
  }
}
