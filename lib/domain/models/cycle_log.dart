import 'package:hive/hive.dart';

part 'cycle_log.g.dart';

@HiveType(typeId: 0)
class CycleLog extends HiveObject {
  @HiveField(0)
  final DateTime startDate;

  @HiveField(1)
  final DateTime? endDate;

  @HiveField(2)
  final String? notes;

  CycleLog({
    required this.startDate,
    this.endDate,
    this.notes,
  });
}

@HiveType(typeId: 1)
class SymptomLog extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final List<String> symptoms;

  @HiveField(2)
  final int moodRating; // 1-5

  @HiveField(3)
  final String? notes;

  SymptomLog({
    required this.date,
    required this.symptoms,
    required this.moodRating,
    this.notes,
  });
}
