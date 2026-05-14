import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/data/storage/data_export_service.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';
import 'package:private_tracker_app/domain/models/custom_tag.dart';

void main() {
  late DataExportService exportService;

  setUp(() {
    exportService = DataExportService();
  });

  group('DataExportService', () {
    test('exportDataToCsv should generate a comprehensive, sorted CSV', () async {
      final cycleLogs = [
        CycleLog(
          id: 'c1',
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 3, 5),
          flowIntensity: 4,
          notes: 'Heavier than usual',
          updatedAt: DateTime(2026, 3, 5, 10),
        ),
      ];

      final symptomLogs = [
        SymptomLog(
          id: 's1',
          date: DateTime(2026, 3, 3),
          symptoms: const ['Cramps', 'Headache'],
          moodRating: 2,
          basalBodyTemperature: 98.2,
          cervicalFluidType: 'Sticky',
          lhTestPositive: true,
          notes: 'Afternoon fatigue',
          updatedAt: DateTime(2026, 3, 3, 20),
        ),
        SymptomLog(
          id: 's2',
          date: DateTime(2026, 3, 10),
          symptoms: const ['Bloating'],
          moodRating: 4,
          updatedAt: DateTime(2026, 3, 10, 9),
        ),
      ];

      final customTags = [
        CustomTag(id: 't1', name: 'Migraine', updatedAt: DateTime(2026, 1, 1)),
      ];

      final csv = await exportService.exportDataToCsv(
        cycleEvents: cycleLogs,
        symptomLogs: symptomLogs,
        customTags: customTags,
      );

      final lines = csv.split('\r\n');
      
      // Verify Header
      expect(lines[0], 'Date,Type,End Date,Symptoms,Mood,Flow,BBT,Fluid,LH Test,Notes,Last Updated,ID');

      // Verify Sorting (Newest first: 2026-03-10, then 03-03, then 03-01)
      expect(lines[1], contains('2026-03-10,Symptom'));
      expect(lines[2], contains('2026-03-03,Symptom'));
      expect(lines[3], contains('2026-03-01,Cycle'));

      // Verify Symptom details (s1)
      expect(lines[2], contains('Cramps; Headache,2,,98.2,Sticky,Positive,Afternoon fatigue'));
      
      // Verify Cycle details (c1)
      expect(lines[3], contains('2026-03-01,Cycle,2026-03-05,,,4/5,,,,Heavier than usual'));
    });
  });
}
