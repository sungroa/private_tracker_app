import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/presentation/widgets/custom_calendar/calendar_grid.dart';
import 'package:private_tracker_app/presentation/widgets/custom_calendar/calendar_day_cell.dart';

void main() {
  group('CustomCalendar Widget Tests', () {
    final testMonth = DateTime(2026, 4, 1);
    
    String _formatKey(DateTime date) => 
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    testWidgets('CustomCalendarGrid renders correct number of days for April 2026', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCalendarGrid(
              focusedDay: testMonth,
              calendarEventMap: const {},
              symptomMap: const {},
              onDaySelected: (_) {},
            ),
          ),
        ),
      );

      // April 2026 starts on Wednesday (offset 3)
      // Days in April: 30
      // Total cells in a 5-week grid (used in code if <= 35) or 6-week:
      // 3 + 30 = 33. Code uses 35 cells minimum.
      
      final dayCells = find.byType(CalendarDayCell);
      expect(dayCells, findsNWidgets(35));
      
      // Verify April 1st is present and not marked as outside
      // Filter for the one that is NOT outside the month
      final april1Cell = tester.widgetList<CalendarDayCell>(find.byType(CalendarDayCell))
          .firstWhere((c) => c.date.day == 1 && !c.isOutsideMonth);
      expect(april1Cell, isNotNull);

      // Verify April 30th is present and not marked as outside
      final april30Cell = tester.widgetList<CalendarDayCell>(find.byType(CalendarDayCell))
          .firstWhere((c) => c.date.day == 30 && !c.isOutsideMonth);
      expect(april30Cell, isNotNull);
    });

    testWidgets('CalendarDayCell shows bleeding span background', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarDayCell(
              date: DateTime(2026, 4, 10),
              isBleeding: true,
              isStartOfSpan: true,
              isEndOfSpan: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the Container with the semi-transparent red background
      final containerFinder = find.byType(Container);
      bool foundSpan = false;
      
      for (final widget in tester.widgetList<Container>(containerFinder)) {
        if (widget.decoration is BoxDecoration) {
          final deco = widget.decoration as BoxDecoration;
          // Use a instead of deprecated opacity. Comparing doubles with small delta.
          if ((deco.color?.a ?? 0) > 0.19 && (deco.color?.a ?? 0) < 0.21 && deco.borderRadius != null) {
            foundSpan = true;
            break;
          }
        }
      }
      expect(foundSpan, true);
    });

    testWidgets('Selecting a day triggers onDaySelected callback', (WidgetTester tester) async {
      DateTime? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCalendarGrid(
              focusedDay: testMonth,
              calendarEventMap: const {},
              symptomMap: const {},
              onDaySelected: (day) => selected = day,
            ),
          ),
        ),
      );

      await tester.tap(find.text('15'));
      expect(selected, isNotNull);
      expect(selected!.day, 15);
      expect(selected!.month, 4);
    });

    testWidgets('Symptom markers are displayed on relevant days', (WidgetTester tester) async {
      final symptomDay = DateTime(2026, 4, 15);
      final symptomMap = {
        _formatKey(symptomDay): SymptomLog(
          date: symptomDay,
          symptoms: ['Cramps'],
          moodRating: 3,
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCalendarGrid(
              focusedDay: testMonth,
              calendarEventMap: const {},
              symptomMap: symptomMap,
              onDaySelected: (_) {},
            ),
          ),
        ),
      );

      // The marker for symptoms is Icons.brightness_1 (dot)
      expect(find.byIcon(Icons.brightness_1), findsOneWidget);
    });
  });
}
