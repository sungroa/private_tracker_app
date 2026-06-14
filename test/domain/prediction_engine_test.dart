import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/domain/calculators/prediction_engine.dart';

void main() {
  group('PredictionEngine Tests', () {
    group('predictFertilityWindow (single-cycle)', () {
      test('returns empty list when period start is null', () {
        expect(PredictionEngine.predictFertilityWindow(null), isEmpty);
      });

      test('returns exactly 6 dates', () {
        final result = PredictionEngine.predictFertilityWindow(DateTime.utc(2026, 6, 1));
        expect(result.length, 6);
      });

      test('fertile window ends 14 days before period start (ovulation day)', () {
        final periodStart = DateTime.utc(2026, 6, 1);
        final window = PredictionEngine.predictFertilityWindow(periodStart);
        // Ovulation = period - 14 days = May 18. Window last day = ovulation day.
        final expectedOvulation = DateTime.utc(2026, 5, 18);
        expect(window.last, expectedOvulation);
      });

      test('fertile window starts 5 days before ovulation day', () {
        final periodStart = DateTime.utc(2026, 6, 1);
        final window = PredictionEngine.predictFertilityWindow(periodStart);
        // Window starts May 13 (18 - 5 days)
        final expectedStart = DateTime.utc(2026, 5, 13);
        expect(window.first, expectedStart);
      });

      test('window dates are consecutive', () {
        final window = PredictionEngine.predictFertilityWindow(DateTime.utc(2026, 6, 1));
        for (int i = 1; i < window.length; i++) {
          expect(
            window[i].difference(window[i - 1]).inDays,
            1,
            reason: 'Window days must be consecutive',
          );
        }
      });
    });

    group('predictAllFertilityWindows (multi-cycle)', () {
      test('returns empty list for empty input', () {
        expect(PredictionEngine.predictAllFertilityWindows([]), isEmpty);
      });

      test('single period start → 6 dates (same as predictFertilityWindow)', () {
        final start = DateTime.utc(2026, 6, 1);
        final result = PredictionEngine.predictAllFertilityWindows([start]);
        final reference = PredictionEngine.predictFertilityWindow(start);
        expect(result.length, reference.length);
        for (int i = 0; i < result.length; i++) {
          expect(result[i].day, reference[i].day);
          expect(result[i].month, reference[i].month);
          expect(result[i].year, reference[i].year);
        }
      });

      test('three well-spaced periods → 18 unique dates', () {
        final periods = [
          DateTime.utc(2026, 4, 1),
          DateTime.utc(2026, 5, 1),
          DateTime.utc(2026, 6, 1),
        ];
        final result = PredictionEngine.predictAllFertilityWindows(periods);
        // All 3 windows should be non-overlapping for 30-day spacing
        expect(result.length, 18);
      });

      test('result is sorted chronologically', () {
        final periods = [
          DateTime.utc(2026, 6, 1),
          DateTime.utc(2026, 4, 1),
          DateTime.utc(2026, 5, 1),
        ];
        final result = PredictionEngine.predictAllFertilityWindows(periods);
        for (int i = 1; i < result.length; i++) {
          expect(
            result[i].isAfter(result[i - 1]) || result[i].isAtSameMomentAs(result[i - 1]),
            isTrue,
            reason: 'Dates must be sorted ascending',
          );
        }
      });

      test('deduplicates overlapping days from very short cycles', () {
        // Force overlap: two cycles only 15 days apart means their fertility windows
        // (ending 14 days before each) may share some days.
        final periods = [
          DateTime.utc(2026, 6, 1),
          DateTime.utc(2026, 6, 16), // 15 days apart → fertile windows overlap
        ];
        final window1 = PredictionEngine.predictFertilityWindow(periods[0]);
        final window2 = PredictionEngine.predictFertilityWindow(periods[1]);
        final allUnique = PredictionEngine.predictAllFertilityWindows(periods);

        // Union of both windows deduplicated
        final combined = {...window1, ...window2}.length;
        expect(allUnique.length, combined);
      });

      test('no duplicate dates in result regardless of input', () {
        final periods = [
          DateTime.utc(2026, 5, 1),
          DateTime.utc(2026, 6, 1),
          DateTime.utc(2026, 7, 1),
          DateTime.utc(2026, 8, 1),
        ];
        final result = PredictionEngine.predictAllFertilityWindows(periods);
        final uniqueDays = result
            .map((d) => '${d.year}-${d.month}-${d.day}')
            .toSet();
        expect(result.length, uniqueDays.length, reason: 'No duplicates allowed');
      });
    });
  });
}
