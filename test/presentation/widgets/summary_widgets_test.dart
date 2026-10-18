import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/domain/trends_calculator.dart';
import 'package:private_tracker_app/presentation/widgets/summary_line_chart.dart';
import 'package:private_tracker_app/presentation/widgets/summary_trend_card.dart';

void main() {
  group('SummaryLineChart Tests', () {
    testWidgets('renders "No mood data" when empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SummaryLineChart(data: [])),
        ),
      );

      expect(find.text('No mood data yet'), findsOneWidget);
    });

    testWidgets('renders CustomPaint when data is present', (WidgetTester tester) async {
      final data = [MoodPoint(DateTime(2026, 1, 1), 3), MoodPoint(DateTime(2026, 1, 2), 4)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SummaryLineChart(data: data)),
        ),
      );

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      expect(find.text('No mood data yet'), findsNothing);
    });
  });

  group('SummaryTrendCard Tests', () {
    testWidgets('renders title, value, and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryTrendCard(
              title: 'Average Cycle',
              value: '28 days',
              subtitle: 'Based on 5 cycles',
              icon: Icons.calendar_today,
            ),
          ),
        ),
      );

      expect(find.text('Average Cycle'), findsOneWidget);
      expect(find.text('28 days'), findsOneWidget);
      expect(find.text('Based on 5 cycles'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });
  });
}
