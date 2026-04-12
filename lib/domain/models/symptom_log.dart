import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

@immutable
class SymptomLog {
  final String id;
  final DateTime date;
  final UnmodifiableListView<String> symptoms;
  final int moodRating; // 1-5
  final String? notes;
  final double? basalBodyTemperature;
  final String? cervicalFluidType;
  final bool? lhTestPositive;

  SymptomLog({
    String? id,
    required this.date,
    required List<String> symptoms,
    required this.moodRating,
    this.notes,
    this.basalBodyTemperature,
    this.cervicalFluidType,
    this.lhTestPositive,
  })  : id = id ?? const Uuid().v4(),
        symptoms = UnmodifiableListView(List.from(symptoms)),
        assert(moodRating >= 1 && moodRating <= 5, 'Mood rating must be between 1 and 5'),
        assert(basalBodyTemperature == null || (basalBodyTemperature >= 35.0 && basalBodyTemperature <= 110.0), 'BBT must be a physiologically valid temperature');

  SymptomLog copyWith({
    String? id,
    DateTime? date,
    List<String>? symptoms,
    int? moodRating,
    String? notes,
    double? basalBodyTemperature,
    String? cervicalFluidType,
    bool? lhTestPositive,
  }) {
    return SymptomLog(
      id: id ?? this.id,
      date: date ?? this.date,
      symptoms: symptoms ?? this.symptoms,
      moodRating: moodRating ?? this.moodRating,
      notes: notes ?? this.notes,
      basalBodyTemperature: basalBodyTemperature ?? this.basalBodyTemperature,
      cervicalFluidType: cervicalFluidType ?? this.cervicalFluidType,
      lhTestPositive: lhTestPositive ?? this.lhTestPositive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'symptoms': symptoms.toList(),
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SymptomLog &&
        other.id == id &&
        other.date.isAtSameMomentAs(date) &&
        const ListEquality().equals(other.symptoms, symptoms) &&
        other.moodRating == moodRating &&
        other.notes == notes &&
        other.basalBodyTemperature == basalBodyTemperature &&
        other.cervicalFluidType == cervicalFluidType &&
        other.lhTestPositive == lhTestPositive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        symptoms.hashCode ^
        moodRating.hashCode ^
        notes.hashCode ^
        basalBodyTemperature.hashCode ^
        cervicalFluidType.hashCode ^
        lhTestPositive.hashCode;
  }
}
