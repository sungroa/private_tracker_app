import 'dart:convert';

class SharedPhaseData {
  SharedPhaseData({
    required this.nextPeriodDate,
    required this.fertilityWindowStart,
    required this.fertilityWindowEnd,
    required this.generatedAt,
  });

  factory SharedPhaseData.fromMap(Map<String, dynamic> map) {
    return SharedPhaseData(
      nextPeriodDate: DateTime.parse(map['p']),
      fertilityWindowStart: DateTime.parse(map['fs']),
      fertilityWindowEnd: DateTime.parse(map['fe']),
      generatedAt: DateTime.parse(map['g']),
    );
  }

  factory SharedPhaseData.fromJson(String source) => SharedPhaseData.fromMap(json.decode(source));
  final DateTime nextPeriodDate;
  final DateTime fertilityWindowStart;
  final DateTime fertilityWindowEnd;
  final DateTime generatedAt;

  Map<String, dynamic> toMap() {
    return {
      'p': nextPeriodDate.toIso8601String(),
      'fs': fertilityWindowStart.toIso8601String(),
      'fe': fertilityWindowEnd.toIso8601String(),
      'g': generatedAt.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());
}
