import '../../domain/models/custom_tag.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/symptom_log.dart';

/// Static utility class to handle Domain <-> Map conversion.
/// 
/// This class lives in the Data layer to keep Domain models pure and
/// decoupled from serialization formats (like JSON/Map).
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
      id: map['id'],
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      notes: map['notes'],
      flowIntensity: map['flowIntensity'] ?? 3,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
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
      id: map['id'],
      date: DateTime.parse(map['date']),
      symptoms: List<String>.from(map['symptoms']),
      moodRating: map['moodRating'],
      notes: map['notes'],
      basalBodyTemperature: map['basalBodyTemperature']?.toDouble(),
      cervicalFluidType: map['cervicalFluidType'],
      lhTestPositive: map['lhTestPositive'],
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
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
      id: map['id'],
      name: map['name'],
      isDefault: map['isDefault'] ?? false,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}
