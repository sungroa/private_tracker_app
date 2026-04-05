import 'package:csv/csv.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/symptom_log.dart';

class DataExportService {
  /// Exports all data to a CSV string.
  Future<String> exportDataToCsv({
    required List<CycleEvent> cycleEvents,
    required List<SymptomLog> symptomLogs,
  }) async {
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
    
    return Csv().encode(rows);
  }
}
