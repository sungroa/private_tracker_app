import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/presentation/widgets/custom_calendar/calendar_grid.dart';
import 'package:private_tracker_app/presentation/widgets/custom_calendar/calendar_day_cell.dart';
import '../helpers/test_model_factory.dart';

/// Helper to wrap a [CustomCalendarGrid] in a scrollable scaffold, matching the
/// production layout in [TrackingCalendarPage].  Without this, the 42-cell grid
/// overflows the default 600px test viewport.
Widget _buildTestHarness(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: child,
      ),
    ),
  );
}

void main() {
  group('CustomCalendar Widget Tests', () {
    final testMonth = DateTime(2026, 4, 1);
    
    String formatKey(DateTime date) => 
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    testWidgets('CustomCalendarGrid renders correct number of days for April 2026', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          CustomCalendarGrid(
            focusedDay: testMonth,
            calendarEventMap: const {},
            symptomMap: const {},
            onDaySelected: (_) {},
          ),
        ),
      );

      // April 2026 starts on Wednesday (offset 3), Days in April: 30.
      // Grid always renders 42 cells (6 full rows) regardless of month
      // to prevent layout overflow during month transitions.
      
      final dayCells = find.byType(CalendarDayCell);
      expect(dayCells, findsNWidgets(42));
      
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
        _buildTestHarness(
          CustomCalendarGrid(
            focusedDay: testMonth,
            calendarEventMap: const {},
            symptomMap: const {},
            onDaySelected: (day) => selected = day,
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
        formatKey(symptomDay): TestModelFactory.createSymptomLog(
          date: symptomDay,
          symptoms: const ['Cramps'],
          moodRating: 3,
        ),
      };

      await tester.pumpWidget(
        _buildTestHarness(
          CustomCalendarGrid(
            focusedDay: testMonth,
            calendarEventMap: const {},
            symptomMap: symptomMap,
            onDaySelected: (_) {},
          ),
        ),
      );

      // The marker for symptoms is Icons.brightness_1 (dot)
      expect(find.byIcon(Icons.brightness_1), findsOneWidget);
    });

    testWidgets('Regression: month transition between 5-row and 6-row months produces no errors', (WidgetTester tester) async {
      // May 2026 naturally needs 6 rows (starts Friday, 31 days → 37 cells).
      // April 2026 naturally needs 5 rows (starts Wednesday, 30 days → 33 cells).
      // Switching between them used to cause a transient layout overflow because
      // the grid height snapped while the AnimatedContainer padding was animating.
      final List<FlutterErrorDetails> errors = [];
      final originalHandler = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);

      try {
        // Start with May (6-row month)
        await tester.pumpWidget(
          _buildTestHarness(
            CustomCalendarGrid(
              focusedDay: DateTime(2026, 5, 1),
              calendarEventMap: const {},
              symptomMap: const {},
              onDaySelected: (_) {},
            ),
          ),
        );
        expect(find.byType(CalendarDayCell), findsNWidgets(42));

        // Switch to April (5-row month) — this is the transition that used to fail.
        await tester.pumpWidget(
          _buildTestHarness(
            CustomCalendarGrid(
              focusedDay: DateTime(2026, 4, 1),
              calendarEventMap: const {},
              symptomMap: const {},
              onDaySelected: (_) {},
            ),
          ),
        );
        expect(find.byType(CalendarDayCell), findsNWidgets(42));

        // And back to May
        await tester.pumpWidget(
          _buildTestHarness(
            CustomCalendarGrid(
              focusedDay: DateTime(2026, 5, 1),
              calendarEventMap: const {},
              symptomMap: const {},
              onDaySelected: (_) {},
            ),
          ),
        );
        expect(find.byType(CalendarDayCell), findsNWidgets(42));

        // No Flutter errors should have been recorded during any transition.
        expect(errors, isEmpty, reason: 'Month transition should not produce layout overflow');
      } finally {
        FlutterError.onError = originalHandler;
      }
    });
  });
}
