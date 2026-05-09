import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:private_tracker_app/presentation/sheets/unified_logging_sheet.dart';
import 'package:private_tracker_app/presentation/providers/symptom_provider.dart';
import 'package:private_tracker_app/presentation/providers/cycle_provider.dart';
import 'package:private_tracker_app/presentation/providers/tag_provider.dart';


class MockSymptomProvider extends Mock implements SymptomProvider {}
class MockCycleProvider extends Mock implements CycleProvider {}
class MockTagProvider extends Mock implements TagProvider {}

void main() {
  late MockSymptomProvider mockSymptomProvider;
  late MockCycleProvider mockCycleProvider;
  late MockTagProvider mockTagProvider;

  setUp(() {
    mockSymptomProvider = MockSymptomProvider();
    mockCycleProvider = MockCycleProvider();
    mockTagProvider = MockTagProvider();

    when(() => mockTagProvider.tags).thenReturn([]);
    when(() => mockTagProvider.isLoading).thenReturn(false);
    when(() => mockTagProvider.refresh()).thenAnswer((_) async {});
  });

  Widget createLoggingSheet() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SymptomProvider>.value(value: mockSymptomProvider),
        ChangeNotifierProvider<CycleProvider>.value(value: mockCycleProvider),
        ChangeNotifierProvider<TagProvider>.value(value: mockTagProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: UnifiedLoggingSheet(
            selectedDay: DateTime(2023, 10, 10),
          ),
        ),
      ),
    );
  }

  testWidgets('UnifiedLoggingSheet renders and switches tabs', (WidgetTester tester) async {
    await tester.pumpWidget(createLoggingSheet());
    await tester.pumpAndSettle();

    expect(find.text('Daily Log'), findsOneWidget);
    expect(find.text('Log Cycle'), findsOneWidget);

    // Initial state should show Daily Log
    expect(find.byKey(const ValueKey('daily_sheet')), findsOneWidget);
    expect(find.byKey(const ValueKey('cycle_sheet')), findsNothing);

    // Switch to Log Cycle
    await tester.tap(find.text('Log Cycle'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('daily_sheet')), findsNothing);
    expect(find.byKey(const ValueKey('cycle_sheet')), findsOneWidget);
  });
}
