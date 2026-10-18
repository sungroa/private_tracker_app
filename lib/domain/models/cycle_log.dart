import 'package:meta/meta.dart';

/// Represents a menstruation cycle entry (period log).
///
/// This is a pure domain model, decoupled from persistence frameworks (like Hive).
/// It follows the Clean Architecture principle that business objects should be
/// frameworks-agnostic.
@immutable
class CycleLog {
  /// Creates a [CycleLog] with validation.
  ///
  /// Following "Technical Excellence" principles, the constructor is now "pure".
  /// ID generation and timestamping should be handled by a factory or the
  /// repository layer before instantiation.
  CycleLog({
    required this.id,
    required this.startDate,
    this.endDate,
    this.notes,
    this.flowIntensity = 3,
    required this.updatedAt,
  }) : assert(flowIntensity >= 1 && flowIntensity <= 5, 'Flow intensity must be between 1 and 5'),
       assert(
         endDate == null || !endDate.isBefore(startDate),
         'End date cannot be before start date',
       );

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

  /// The last time this record was modified.
  final DateTime updatedAt;

  /// Creates a copy of this object with potentially changed values.
  /// (W5) Uses Sentinel pattern to distinguish between null (no change) and
  /// explicitly providing a null value for nullable fields.
  CycleLog copyWith({
    String? id,
    DateTime? startDate,
    Object? endDate = _sentinel,
    Object? notes = _sentinel,
    int? flowIntensity,
    DateTime? updatedAt,
  }) {
    return CycleLog(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate == _sentinel ? this.endDate : (endDate as DateTime?),
      notes: notes == _sentinel ? this.notes : (notes as String?),
      flowIntensity: flowIntensity ?? this.flowIntensity,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const _sentinel = Object();

  /// Returns a new instance of [CycleLog] with the [endDate] explicitly set to null.
  /// (Maintenance: prefer copyWith(endDate: null) now that it supports it).
  CycleLog clearEndDate() => copyWith(endDate: null);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CycleLog &&
        other.id == id &&
        other.startDate.isAtSameMomentAs(startDate) &&
        (other.endDate == null
            ? endDate == null
            : endDate != null && other.endDate!.isAtSameMomentAs(endDate!)) &&
        other.notes == notes &&
        other.flowIntensity == flowIntensity &&
        other.updatedAt.isAtSameMomentAs(updatedAt);
  }

  @override
  int get hashCode {
    return Object.hash(id, startDate, endDate, notes, flowIntensity, updatedAt);
  }
}

/// Extensions on [CycleLog] to provide presentation-friendly utility getters.
extension CycleLogX on CycleLog {
  /// Returns a displayable string representation of the flow intensity.
  String get flowIntensityDisplayName => "$flowIntensity / 5";
}
