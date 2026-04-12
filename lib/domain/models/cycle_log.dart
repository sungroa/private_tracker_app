import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// Represents a menstruation cycle entry (period log).
/// 
/// This is a pure domain model, decoupled from persistence frameworks (like Hive).
/// It follows the Clean Architecture principle that business objects should be 
/// frameworks-agnostic.
@immutable
class CycleLog {
  /// Unique identifier for the log entry.
  final String id;

  /// The date when the period started.
  final DateTime startDate;

  /// The date when the period ended. If null, the period is currently in progress.
  final DateTime? endDate;

  /// Optional personal notes about this cycle.
  final String? notes;

  /// Subjective measure of menstruation flow, typically on a scale of 1-5.
  final int flowIntensity;

  /// Creates a [CycleLog] with validation.
  /// 
  /// [id] If null, a new v4 UUID will be generated.
  /// [flowIntensity] Must be between 1 and 5.
  /// [endDate] Must not be before [startDate].
  CycleLog({
    String? id,
    required this.startDate,
    this.endDate,
    this.notes,
    this.flowIntensity = 3,
  })  : id = id ?? const Uuid().v4(),
        assert(flowIntensity >= 1 && flowIntensity <= 5, 'Flow intensity must be between 1 and 5'),
        assert(endDate == null || !endDate.isBefore(startDate), 'End date cannot be before start date');

  /// Creates a copy of this object with potentially changed values.
  CycleLog copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    int? flowIntensity,
  }) {
    return CycleLog(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      // Note: This pattern doesn't allow setting endDate back to null if it was already set.
      // Use [clearEndDate] for that specific transformation.
      endDate: endDate ?? this.endDate, 
      notes: notes ?? this.notes,
      flowIntensity: flowIntensity ?? this.flowIntensity,
    );
  }

  /// Returns a new instance of [CycleLog] with the [endDate] explicitly set to null.
  /// Useful for marking a period as "still in progress".
  CycleLog clearEndDate() {
    return CycleLog(
      id: id,
      startDate: startDate,
      endDate: null,
      notes: notes,
      flowIntensity: flowIntensity,
    );
  }

  /// Converts this domain model into a Map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'flowIntensity': flowIntensity,
    };
  }

  /// Creates a [CycleLog] from a [Map].
  factory CycleLog.fromMap(Map<String, dynamic> map) {
    return CycleLog(
      id: map['id'],
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      notes: map['notes'],
      flowIntensity: map['flowIntensity'] ?? 3,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CycleLog &&
        other.id == id &&
        other.startDate.isAtSameMomentAs(startDate) &&
        (other.endDate == null ? endDate == null : endDate != null && other.endDate!.isAtSameMomentAs(endDate!)) &&
        other.notes == notes &&
        other.flowIntensity == flowIntensity;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        notes.hashCode ^
        flowIntensity.hashCode;
  }
}

/// Extensions on [CycleLog] to provide presentation-friendly utility getters.
extension CycleLogX on CycleLog {
  /// Returns a displayable string representation of the flow intensity.
  String get flowIntensityDisplayName => "$flowIntensity / 5";
}
