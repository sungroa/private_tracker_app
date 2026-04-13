import 'dart:isolate';
import '../../domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';

class DataExportService {
  /// Exports all data to a CSV string.
  /// 
  /// (W1/W10) Offloaded to background isolate to keep UI responsive during large exports.
  Future<String> exportDataToCsv({
    required List<CycleLog> cycleEvents,
    required List<SymptomLog> symptomLogs,
  }) async {
    return Isolate.run(() => _generateCsv(cycleEvents, symptomLogs));
  }
}

String _generateCsv(List<CycleLog> cycleEvents, List<SymptomLog> symptomLogs) {
  final List<List<dynamic>> rows = [];
  rows.add(['Log Type', 'Start Date/Date', 'End Date', 'Symptoms', 'Mood Rating', 'BBT', 'Fluid', 'LH Test', 'Notes']);
  
  for (var log in cycleEvents) {
    rows.add([
      'Cycle',
      log.startDate.toIso8601String().split('T')[0],
      log.endDate?.toIso8601String().split('T')[0] ?? '',
      '',
      '',
      '',
      '',
      '',
      log.notes ?? '',
    ]);
  }
  
  for (var log in symptomLogs) {
    rows.add([
      'Symptom',
      log.date.toIso8601String().split('T')[0],
      '',
      log.symptoms.join('; '),
      log.moodRating.toString(),
      log.basalBodyTemperature?.toString() ?? '',
      log.cervicalFluidType ?? '',
      log.lhTestPositive == true ? 'Positive' : (log.lhTestPositive == false ? 'Negative' : ''),
      log.notes ?? '',
    ]);
  }
  
  return _manualToCsv(rows);
}

String _manualToCsv(List<List<dynamic>> rows) {
  // (W1/W10) Manual CSV implementation to ensure zero-dependency domain logic 
  // and maximum compatibility with standard spreadsheets.
  return rows.map((row) {
    return row.map((field) {
      final str = field.toString().replaceAll('"', '""');
      if (str.contains(',') || str.contains('\n') || str.contains('"')) {
        return '"$str"';
      }
      return str;
    }).join(',');
  }).join('\r\n');
}
