import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/domain/models/trends.dart';
import 'package:private_tracker_app/presentation/analytics/widgets/bbt_chart.dart';
import 'package:private_tracker_app/presentation/theme/app_theme.dart';
import 'package:private_tracker_app/presentation/widgets/summary_line_chart.dart';
import 'package:private_tracker_app/presentation/widgets/summary_trend_card.dart';

void main() {
  group('Accessibility & Semantics Tests', () {
    testWidgets('SummaryTrendCard is wrapped in MergeSemantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SummaryTrendCard(
              title: "Cycle Length",
              value: "28 days",
              subtitle: "Regular pattern",
            ),
          ),
        ),
      );

      // Verify that MergeSemantics is present
      expect(find.byType(MergeSemantics), findsOneWidget);
    });

    testWidgets('SummaryLineChart produces correct semantic description', (
      WidgetTester tester,
    ) async {
      final logs = [
        MoodPoint(DateTime(2026, 6, 1), 3), // Doing okay
        MoodPoint(DateTime(2026, 6, 2), 5), // Excellent mood
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: SummaryLineChart(data: logs, height: 100)),
        ),
      );

      // Average mood is (3+5)/2 = 4 (Feeling good)
      // Latest mood is 5 (Excellent mood)
      // Expect Semantics with matching label
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                "Mood trend chart showing 2 logs. Average mood rating is Feeling good. Latest logged mood is Excellent mood.",
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('BbtChart produces correct semantic analysis description', (
      WidgetTester tester,
    ) async {
      final records = [
        BbtPoint(cycleDay: 1, date: DateTime(2026, 6, 1), temperature: 97.2),
        BbtPoint(cycleDay: 2, date: DateTime(2026, 6, 2), temperature: 98.6),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: BbtChart(bbtHistory: records)),
        ),
      );

      // Average temperature is (97.2 + 98.6) / 2 = 97.9
      // Expect Semantics with matching label
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                "Basal Body Temperature chart showing 2 recorded temperatures. Average temperature is 97.9 degrees. Lowest temperature is 97.2 degrees. Highest temperature is 98.6 degrees. ",
      );
      expect(semanticsFinder, findsOneWidget);
    });
  });
}
