import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';
import 'package:private_tracker_app/presentation/sheets/day_summary_sheet.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('DaySummarySheet Tests', () {
    final testDate = DateTime(2026, 5, 13);

    testWidgets('displays symptom log notes when present', (WidgetTester tester) async {
      final symptomLog = SymptomLog(
        id: '1',
        date: testDate,
        symptoms: const ['Cramps', 'Headache'],
        moodRating: 4,
        notes: 'This is a test note for the daily log.',
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          DaySummarySheet(
            selectedDay: testDate,
            symptomLog: symptomLog,
            onEditDailyLog: () {},
            onEditPeriodLog: () {},
          ),
        ),
      );

      // Verify symptoms and mood are visible (existing behavior)
      expect(find.text('Cramps, Headache'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);

      // Verify notes are visible (should fail currently)
      expect(find.text('This is a test note for the daily log.'), findsOneWidget);
    });

    testWidgets('displays cycle log notes when present', (WidgetTester tester) async {
      final cycleLog = CycleLog(
        id: '1',
        startDate: testDate,
        flowIntensity: 3,
        notes: 'Cycle notes.',
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          DaySummarySheet(
            selectedDay: testDate,
            cycleLog: cycleLog,
            onEditDailyLog: () {},
            onEditPeriodLog: () {},
          ),
        ),
      );

      expect(find.text('3 / 5'), findsOneWidget);
      expect(find.text('Cycle notes.'), findsOneWidget);
    });
  });
}
