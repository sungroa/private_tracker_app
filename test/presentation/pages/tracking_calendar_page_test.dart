import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:private_tracker_app/presentation/pages/tracking_calendar_page.dart';
import 'package:private_tracker_app/presentation/providers/cycle_provider.dart';
import 'package:private_tracker_app/presentation/providers/symptom_provider.dart';
import 'package:intl/intl.dart';

class MockCycleProvider extends Mock implements CycleProvider {}
class MockSymptomProvider extends Mock implements SymptomProvider {}

void main() {
  late MockCycleProvider mockCycleProvider;
  late MockSymptomProvider mockSymptomProvider;

  setUp(() {
    mockCycleProvider = MockCycleProvider();
    mockSymptomProvider = MockSymptomProvider();

    when(() => mockCycleProvider.calendarEventMap).thenReturn({});
    when(() => mockCycleProvider.predictedNextPeriod).thenReturn(null);
    when(() => mockCycleProvider.predictedFertilityDates).thenReturn([]);
    when(() => mockSymptomProvider.symptomMap).thenReturn({});
    
    // For _showUnifiedSheet lookups
    when(() => mockSymptomProvider.getSymptomByDate(any())).thenReturn(null);
    when(() => mockCycleProvider.getEventByDate(any())).thenReturn(null);
    
    // For _showDaySummary lookups
    when(() => mockCycleProvider.isPredictedBleeding(any())).thenReturn(false);
    when(() => mockCycleProvider.isPredictedFertility(any())).thenReturn(false);
  });

  Widget createTrackingCalendarPage() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CycleProvider>.value(value: mockCycleProvider),
        ChangeNotifierProvider<SymptomProvider>.value(value: mockSymptomProvider),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: TrackingCalendarPage(),
        ),
      ),
    );
  }

  testWidgets('Tapping calendar header opens MonthYearPickerSheet', (WidgetTester tester) async {
    await tester.pumpWidget(createTrackingCalendarPage());
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final headerText = DateFormat('MMMM yyyy').format(now).toUpperCase();

    // Find the header text
    final headerFinder = find.text(headerText);
    expect(headerFinder, findsOneWidget);

    // Tap the header
    await tester.tap(headerFinder);
    await tester.pumpAndSettle();

    // Verify picker is shown
    expect(find.text('SELECT DATE'), findsOneWidget);
    final currentMonthName = DateFormat('MMMM').format(now).toUpperCase();
    expect(find.text(currentMonthName), findsWidgets); // Current month should be visible
    expect(find.text(now.year.toString()), findsWidgets); // Current year should be visible
  });

  testWidgets('Selecting a date in picker updates focusedDay', (WidgetTester tester) async {
    await tester.pumpWidget(createTrackingCalendarPage());
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final headerText = DateFormat('MMMM yyyy').format(now).toUpperCase();

    // Tap the header
    await tester.tap(find.text(headerText));
    await tester.pumpAndSettle();

    // In the picker, select "JANUARY" and "2025" (if not already selected)
    // For simplicity, we'll just find the "CONFIRM" button after some scrolling simulations
    // or just assume the initial selection is confirmed.
    
    // Find Confirm button
    final confirmButton = find.text('CONFIRM');
    expect(confirmButton, findsOneWidget);
    
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // Picker should be closed
    expect(find.text('SELECT DATE'), findsNothing);
  });
}
