import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'symptom_log.g.dart';

@HiveType(typeId: 1)
class SymptomLog {
  @HiveField(7, defaultValue: '')
  final String id;

  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final List<String> symptoms;

  @HiveField(2)
  final int moodRating; // 1-5

  @HiveField(3)
  final String? notes;

  @HiveField(4)
  final double? basalBodyTemperature;

  @HiveField(5)
  final String? cervicalFluidType;

  @HiveField(6)
  final bool? lhTestPositive;

  SymptomLog({
    String? id,
    required this.date,
    required this.symptoms,
    required this.moodRating,
    this.notes,
    this.basalBodyTemperature,
    this.cervicalFluidType,
    this.lhTestPositive,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'symptoms': symptoms,
      'moodRating': moodRating,
      'notes': notes,
      'basalBodyTemperature': basalBodyTemperature,
      'cervicalFluidType': cervicalFluidType,
      'lhTestPositive': lhTestPositive,
    };
  }

  factory SymptomLog.fromMap(Map<String, dynamic> map) {
    return SymptomLog(
      id: map['id'],
      date: DateTime.parse(map['date']),
      symptoms: List<String>.from(map['symptoms']),
      moodRating: map['moodRating'],
      notes: map['notes'],
      basalBodyTemperature: map['basalBodyTemperature']?.toDouble(),
      cervicalFluidType: map['cervicalFluidType'],
      lhTestPositive: map['lhTestPositive'],
    );
  }
}
