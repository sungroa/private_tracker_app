import 'dart:isolate';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/symptom_log.dart';
import '../../domain/models/custom_tag.dart';
import 'model_mapper.dart';

class DataExportService {
  /// Exports all data to a CSV string.
  /// 
  /// (W1/W10) Offloaded to background isolate to keep UI responsive during large exports.
  Future<String> exportDataToCsv({
    required List<CycleLog> cycleEvents,
    required List<SymptomLog> symptomLogs,
    required List<CustomTag> customTags,
  }) async {
    return Isolate.run(() => _generateCsv(cycleEvents, symptomLogs, customTags));
  }

  /// Aggregates all user logs and tags into a JSON-ready map for cloud sync or backup.
  /// 
  /// WARNING: Use with caution as this loads all data into memory at once.
  Map<String, dynamic> exportAllDataAsJsonReadyMap({
    required List<CycleLog> cycleLogs,
    required List<SymptomLog> symptomLogs,
    required List<CustomTag> customTags,
  }) {
    return {
      'cycleLogs': cycleLogs.map((l) => ModelMapper.cycleLogToMap(l)).toList(),
      'symptomLogs': symptomLogs.map((l) => ModelMapper.symptomLogToMap(l)).toList(),
      'customTags': customTags.map((t) => ModelMapper.customTagToMap(t)).toList(),
    };
  }
}

String _generateCsv(List<CycleLog> cycleEvents, List<SymptomLog> symptomLogs, List<CustomTag> customTags) {
  final List<List<dynamic>> rows = [];
  
  // (N3) Journal-friendly header: Date first, then Type, then data points.
  rows.add([
    'Date', 
    'Type', 
    'End Date', 
    'Symptoms', 
    'Mood', 
    'Flow', 
    'BBT', 
    'Fluid', 
    'LH Test', 
    'Notes', 
    'Last Updated', 
    'ID'
  ]);
  
  // Combine all logs into a single list for chronological sorting
  final List<_ExportItem> items = [
    ...cycleEvents.map((e) => _ExportItem(e.startDate, 'Cycle', e)),
    ...symptomLogs.map((s) => _ExportItem(s.date, 'Symptom', s)),
  ];
  
  // Sort by date descending (newest first) for a "Journal" experience
  items.sort((a, b) => b.date.compareTo(a.date));
  
  for (var item in items) {
    if (item.data is CycleLog) {
      final log = item.data as CycleLog;
      rows.add([
        log.startDate.toIso8601String().split('T')[0],
        'Cycle',
        log.endDate?.toIso8601String().split('T')[0] ?? '',
        '', // Symptoms
        '', // Mood
        '${log.flowIntensity}/5', 
        '', // BBT
        '', // Fluid
        '', // LH Test
        log.notes ?? '',
        log.updatedAt.toIso8601String(),
        log.id,
      ]);
    } else if (item.data is SymptomLog) {
      final log = item.data as SymptomLog;
      rows.add([
        log.date.toIso8601String().split('T')[0],
        'Symptom',
        '', // End Date
        log.symptoms.join('; '),
        log.moodRating.toString(),
        '', // Flow
        log.basalBodyTemperature?.toString() ?? '',
        log.cervicalFluidType ?? '',
        log.lhTestPositive == true ? 'Positive' : (log.lhTestPositive == false ? 'Negative' : ''),
        log.notes ?? '',
        log.updatedAt.toIso8601String(),
        log.id,
      ]);
    }
  }
  
  return _manualToCsv(rows);
}

class _ExportItem {
  final DateTime date;
  final String type;
  final dynamic data;
  _ExportItem(this.date, this.type, this.data);
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
