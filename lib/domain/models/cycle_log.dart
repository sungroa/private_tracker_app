import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

export 'symptom_log.dart';

part 'cycle_log.g.dart';

@HiveType(typeId: 0)
class CycleEvent {
  @HiveField(3, defaultValue: '')
  final String id;

  @HiveField(0)
  final DateTime startDate;

  @HiveField(1)
  final DateTime? endDate;

  @HiveField(2)
  final String? notes;

  @HiveField(4, defaultValue: 3)
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
