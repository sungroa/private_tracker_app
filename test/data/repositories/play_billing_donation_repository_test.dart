import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/data/repositories/play_billing_donation_repository.dart';
import 'package:private_tracker_app/data/storage/secure_key_storage.dart';
import 'package:private_tracker_app/domain/models/donation_product.dart';

class MockInAppPurchase extends Mock implements InAppPurchase {}

class MockSecureKeyStorage extends Mock implements SecureKeyStorage {}

class PurchaseParamFake extends Fake implements PurchaseParam {}

void main() {
  setUpAll(() {
    registerFallbackValue(PurchaseParamFake());
  });

  late PlayBillingDonationRepository repository;
  late MockInAppPurchase mockIap;
  late MockSecureKeyStorage mockKeyStorage;
  late StreamController<List<PurchaseDetails>> purchaseStreamController;

  setUp(() {
    mockIap = MockInAppPurchase();
    mockKeyStorage = MockSecureKeyStorage();
    purchaseStreamController = StreamController<List<PurchaseDetails>>.broadcast();

    when(() => mockIap.purchaseStream).thenAnswer((_) => purchaseStreamController.stream);
    when(() => mockKeyStorage.getSupporterStatus()).thenAnswer((_) async => false);

    repository = PlayBillingDonationRepository(mockKeyStorage, iap: mockIap);
  });

  tearDown(() {
    purchaseStreamController.close();
  });

  group('PlayBillingDonationRepository Tests', () {
    test('getDonationProducts should return mapped products when IAP is available', () async {
      when(() => mockIap.isAvailable()).thenAnswer((_) async => true);

      final mockProduct = ProductDetails(
        id: 'tip_coffee_consumable',
        title: 'Coffee Tip',
        description: 'Buy me a coffee',
        price: '\$2.00',
        rawPrice: 2.0,
        currencyCode: 'USD',
      );

      when(() => mockIap.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(productDetails: [mockProduct], notFoundIDs: []),
      );

      final products = await repository.getDonationProducts();

      expect(products.length, 1);
      expect(products.first.id, 'tip_coffee_consumable');
      expect(products.first.formattedPrice, '\$2.00');
    });

    test('getDonationProducts should return empty list when IAP is unavailable', () async {
      when(() => mockIap.isAvailable()).thenAnswer((_) async => false);
      final products = await repository.getDonationProducts();
      expect(products, isEmpty);
    });

    test('purchase should call buyConsumable for non-subscription products', () async {
      const product = DonationProduct(
        id: 'tip_coffee_consumable',
        name: 'Coffee',
        description: '...',
        formattedPrice: '\$2',
        isSubscription: false,
      );

      final mockProductDetails = ProductDetails(
        id: 'tip_coffee_consumable',
        title: '...',
        description: '...',
        price: '...',
        rawPrice: 0,
        currencyCode: '...',
      );

      when(() => mockIap.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(productDetails: [mockProductDetails], notFoundIDs: []),
      );
      when(
        () => mockIap.buyConsumable(purchaseParam: any(named: 'purchaseParam')),
      ).thenAnswer((_) async => true);

      final result = await repository.purchase(product);

      expect(result, true);
      verify(() => mockIap.buyConsumable(purchaseParam: any(named: 'purchaseParam'))).called(1);
    });

    test('Successful purchase update should trigger supporter status change', () async {
      when(() => mockKeyStorage.setSupporterStatus(true)).thenAnswer((_) async => {});

      // Simulate a successful purchase in the stream
      final purchase = PurchaseDetails(
        productID: 'tip_coffee_consumable',
        status: PurchaseStatus.purchased,
        transactionDate: '2026-05-15',
        purchaseID: 'trans_123',
        verificationData: PurchaseVerificationData(
          localVerificationData: '...',
          serverVerificationData: '...',
          source: '...',
        ),
      );

      // Listen to the supporter stream
      final supporterStates = <bool>[];
      repository.isSupporterStream.listen(supporterStates.add);

      purchaseStreamController.add([purchase]);

      // Wait for async processing
      await pumpEventQueue();

      expect(supporterStates.last, true);
      verify(() => mockKeyStorage.setSupporterStatus(true)).called(1);
    });
  });
}
