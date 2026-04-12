import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// Represents a daily health log entry containing symptoms, mood, and FAM metrics.
/// 
/// This model encapsulates all daily data points except for primary cycle information.
/// It uses [UnmodifiableListView] for [symptoms] to ensure domain model immutability.
@immutable
class SymptomLog {
  /// Unique identifier for the log entry.
  final String id;

  /// The date this log entry corresponds to.
  final DateTime date;

  /// A list of symptoms experienced on this day.
  final UnmodifiableListView<String> symptoms;

  /// Subjective mood rating from 1 (Terrible) to 5 (Excellent).
  final int moodRating;

  /// Optional personal notes for the day.
  final String? notes;

  /// Basal Body Temperature (BBT) in degrees F/C.
  final double? basalBodyTemperature;

  /// Categorical type of cervical fluid (e.g., 'Sticky', 'Eggwhite').
  final String? cervicalFluidType;

  /// Result of a Luteinizing Hormone (LH) ovulation test.
  final bool? lhTestPositive;

  /// The last time this record was modified.
  final DateTime updatedAt;

  /// Creates a [SymptomLog] with validation.
  /// 
  /// [moodRating] Defaults to 3 (Neutral). Must be between 1 and 5.
  /// [basalBodyTemperature] If provided, must be within a physiologically valid range.
  SymptomLog({
    String? id,
    required this.date,
    required List<String> symptoms,
    required this.moodRating,
    this.notes,
    this.basalBodyTemperature,
    this.cervicalFluidType,
    this.lhTestPositive,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime(1970),
        symptoms = UnmodifiableListView(List.from(symptoms)),
        assert(moodRating >= 1 && moodRating <= 5, 'Mood rating must be between 1 and 5'),
        assert(basalBodyTemperature == null || (basalBodyTemperature >= 35.0 && basalBodyTemperature <= 110.0), 'BBT must be a physiologically valid temperature');

  /// Creates a copy of this object with potentially changed values.
  SymptomLog copyWith({
    String? id,
    DateTime? date,
    List<String>? symptoms,
    int? moodRating,
    String? notes,
    double? basalBodyTemperature,
    String? cervicalFluidType,
    bool? lhTestPositive,
    DateTime? updatedAt,
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
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts this domain model into a Map for serialization.
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
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Creates a [SymptomLog] from a [Map].
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
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
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

  /// --- Domain Constants ---
  
  /// The standard neutral mood rating.
  static const int neutralMood = 3;
}

/// Extensions on [SymptomLog] to provide presentation-friendly utility getters.
extension SymptomLogX on SymptomLog {
  /// Returns a human-readable string for the [moodRating].
  String get moodDisplayName {
    if (moodRating <= 1) return "Terrible";
    if (moodRating == 2) return "Bad";
    if (moodRating == 3) return "Neutral";
    if (moodRating == 4) return "Good";
    return "Excellent";
  }

  /// Returns a comma-separated summary of all symptoms.
  String get symptomsSummary => symptoms.join(", ");
}
