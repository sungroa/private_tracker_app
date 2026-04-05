import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/domain/trends_calculator.dart';
import 'package:private_tracker_app/presentation/analytics/widgets/bbt_chart.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  testWidgets('BbtChart renders LineChart when data is present', (WidgetTester tester) async {
    final bbtHistory = [
      BbtPoint(cycleDay: 1, temperature: 36.5, date: DateTime(2026, 4, 1)),
      BbtPoint(cycleDay: 2, temperature: 36.6, date: DateTime(2026, 4, 2), hasLhSurge: true),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BbtChart(bbtHistory: bbtHistory),
        ),
      ),
    );

    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('BbtChart shows empty state message when no data', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BbtChart(bbtHistory: []),
        ),
      ),
    );

    expect(find.text('No BBT data for this cycle'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });
}
