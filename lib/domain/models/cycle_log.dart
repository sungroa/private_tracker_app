import 'package:uuid/uuid.dart';
export 'symptom_log.dart';

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
  }) : id = id ?? const Uuid().v4();

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
}
