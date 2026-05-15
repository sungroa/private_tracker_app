import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/models/donation_product.dart';
import 'package:private_tracker_app/domain/repositories/donation_repository.dart';
import 'package:private_tracker_app/presentation/providers/donation_provider.dart';
import 'package:private_tracker_app/presentation/sheets/donation_sheet.dart';
import 'package:provider/provider.dart';

class MockDonationRepository extends Mock implements IDonationRepository {}

void main() {
  late MockDonationRepository mockRepository;
  late StreamController<bool> supporterStreamController;

  setUp(() {
    mockRepository = MockDonationRepository();
    supporterStreamController = StreamController<bool>.broadcast();
    
    when(() => mockRepository.isSupporterStream).thenAnswer((_) => supporterStreamController.stream);
    when(() => mockRepository.isSupporter()).thenAnswer((_) async => false);
    when(() => mockRepository.getDonationProducts()).thenAnswer((_) async => []);
  });

  tearDown(() {
    supporterStreamController.close();
  });

  Widget createTestableWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<DonationProvider>(
        create: (_) => DonationProvider(mockRepository),
        child: const Scaffold(
          body: DonationSheet(),
        ),
      ),
    );
  }

  testWidgets('DonationSheet shows loading state initially', (WidgetTester tester) async {
    final completer = Completer<List<DonationProduct>>();
    when(() => mockRepository.getDonationProducts()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(createTestableWidget());
    await tester.pump();
    
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Clean up
    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('DonationSheet renders header and products', (WidgetTester tester) async {
    final mockProducts = [
      DonationProduct(id: '1', name: 'Coffee', description: 'Buy a coffee', formattedPrice: '\$2.00', isSubscription: false),
    ];
    when(() => mockRepository.getDonationProducts()).thenAnswer((_) async => mockProducts);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Support Privacy Tracker'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('\$2.00'), findsOneWidget);
    expect(find.text('Restore Purchases'), findsOneWidget);
  });
}
