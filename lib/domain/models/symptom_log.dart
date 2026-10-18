import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Represents a daily health log entry containing symptoms, mood, and FAM metrics.
///
/// This model encapsulates all daily data points except for primary cycle information.
/// It uses [UnmodifiableListView] for [symptoms] to ensure domain model immutability.
@immutable
class SymptomLog {
  /// Creates a [SymptomLog] with validation.
  ///
  /// Following "Technical Excellence" principles, the constructor is now "pure".
  SymptomLog({
    required this.id,
    required this.date,
    required List<String> symptoms,
    required this.moodRating,
    this.notes,
    this.basalBodyTemperature,
    this.cervicalFluidType,
    this.lhTestPositive,
    required this.updatedAt,
  }) : symptoms = UnmodifiableListView(List.from(symptoms)),
       assert(moodRating >= 1 && moodRating <= 5, 'Mood rating must be between 1 and 5'),
       assert(
         basalBodyTemperature == null ||
             (basalBodyTemperature >= 35.0 && basalBodyTemperature <= 110.0),
         'BBT must be a physiologically valid temperature',
       );

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

  /// Creates a copy of this object with potentially changed values.
  /// (W5) Uses Sentinel pattern to distinguish between null (no change) and
  /// explicitly providing a null value for nullable fields.
  SymptomLog copyWith({
    String? id,
    DateTime? date,
    List<String>? symptoms,
    int? moodRating,
    Object? notes = _sentinel,
    Object? basalBodyTemperature = _sentinel,
    Object? cervicalFluidType = _sentinel,
    Object? lhTestPositive = _sentinel,
    DateTime? updatedAt,
  }) {
    return SymptomLog(
      id: id ?? this.id,
      date: date ?? this.date,
      symptoms: symptoms ?? this.symptoms,
      moodRating: moodRating ?? this.moodRating,
      notes: notes == _sentinel ? this.notes : (notes as String?),
      basalBodyTemperature: basalBodyTemperature == _sentinel
          ? this.basalBodyTemperature
          : (basalBodyTemperature as double?),
      cervicalFluidType: cervicalFluidType == _sentinel
          ? this.cervicalFluidType
          : (cervicalFluidType as String?),
      lhTestPositive: lhTestPositive == _sentinel ? this.lhTestPositive : (lhTestPositive as bool?),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const _sentinel = Object();

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
        other.lhTestPositive == lhTestPositive &&
        other.updatedAt.isAtSameMomentAs(updatedAt);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      date,
      Object.hashAll(symptoms),
      moodRating,
      notes,
      basalBodyTemperature,
      cervicalFluidType,
      lhTestPositive,
      updatedAt,
    );
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
