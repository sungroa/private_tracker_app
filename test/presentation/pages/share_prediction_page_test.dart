import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/presentation/pages/share_prediction_page.dart';
import 'package:private_tracker_app/presentation/providers/cycle_provider.dart';
import 'package:private_tracker_app/presentation/providers/symptom_provider.dart';
import 'package:private_tracker_app/domain/services/partner_sharing_service.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MockCycleProvider extends Mock implements CycleProvider {}
class MockSymptomProvider extends Mock implements SymptomProvider {}
class MockPartnerSharingService extends Mock implements PartnerSharingService {}

void main() {
  late MockCycleProvider mockCycle;
  late MockSymptomProvider mockSymptom;
  late MockPartnerSharingService mockSharing;

  setUp(() {
    mockCycle = MockCycleProvider();
    mockSymptom = MockSymptomProvider();
    mockSharing = MockPartnerSharingService();

    when(() => mockCycle.cycleEvents).thenReturn([]);
    when(() => mockSymptom.symptomLogs).thenReturn([]);
    when(() => mockSharing.generateShareableLink(any(), any())).thenReturn('https://link.com');
  });

  Widget createWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CycleProvider>.value(value: mockCycle),
        ChangeNotifierProvider<SymptomProvider>.value(value: mockSymptom),
        Provider<PartnerSharingService>.value(value: mockSharing),
      ],
      child: const MaterialApp(
        home: SharePredictionPage(),
      ),
    );
  }

  testWidgets('SharePredictionPage renders QR code', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('Share with Partner'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('SCAN QR CODE'), findsOneWidget);
  });

  testWidgets('Copy Link shows snackbar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Copy Link'));
    await tester.pumpAndSettle();

    expect(find.text('Link copied to clipboard'), findsOneWidget);
  });
}
