import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';


@immutable
class CycleEvent {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final int flowIntensity;

  CycleEvent({
    String? id,
    required this.startDate,
    this.endDate,
    this.notes,
    this.flowIntensity = 3,
  })  : id = id ?? const Uuid().v4(),
        assert(flowIntensity >= 1 && flowIntensity <= 5, 'Flow intensity must be between 1 and 5'),
        assert(endDate == null || !endDate.isBefore(startDate), 'End date cannot be before start date');

  CycleEvent copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    int? flowIntensity,
  }) {
    return CycleEvent(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      // We check for an explicit null vs undefined when actually using copyWith in Dart, 
      // but to keep it simple and match standard Dart copyWith without a special wrapper:
      endDate: endDate ?? this.endDate, 
      notes: notes ?? this.notes,
      flowIntensity: flowIntensity ?? this.flowIntensity,
    );
  }

  // To allow clearing endDate
  CycleEvent clearEndDate() {
    return CycleEvent(
      id: id,
      startDate: startDate,
      endDate: null,
      notes: notes,
      flowIntensity: flowIntensity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'flowIntensity': flowIntensity,
    };
  }

  factory CycleEvent.fromMap(Map<String, dynamic> map) {
    return CycleEvent(
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
    return other is CycleEvent &&
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
