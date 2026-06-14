import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/models/trends.dart';
import 'package:private_tracker_app/presentation/pages/summary_trends_page.dart';
import 'package:private_tracker_app/presentation/providers/cycle_provider.dart';
import 'package:provider/provider.dart';

class MockCycleProvider extends Mock implements CycleProvider {}

void main() {
  late MockCycleProvider mockProvider;

  setUp(() {
    mockProvider = MockCycleProvider();
  });

  Widget createWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<CycleProvider>.value(
        value: mockProvider,
        child: const SummaryTrendsPage(),
      ),
    );
  }

  testWidgets('renders "No data available yet" when trends are null', (WidgetTester tester) async {
    when(() => mockProvider.trends).thenReturn(null);
    
    await tester.pumpWidget(createWidget());
    
    expect(find.text('No data available yet.'), findsOneWidget);
  });

  testWidgets('renders trends when data is present', (WidgetTester tester) async {
    final trendData = TrendData(
      averageCycleLength: 28,
      averagePeriodDuration: 5,
      topSymptoms: [const MapEntry('Cramps', 5)],
      moodHistory: [],
      bbtHistory: [],
      predictedPeriodStarts: [DateTime(2026, 6, 1)],
      predictedFertilityDates: [DateTime(2026, 5, 14)],
    );
    when(() => mockProvider.trends).thenReturn(trendData);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('Your Trends'), findsOneWidget);
    expect(find.text('AVG CYCLE'), findsOneWidget);
    expect(find.text('28d'), findsOneWidget);
    expect(find.text('Cramps'), findsOneWidget);
  });
}
