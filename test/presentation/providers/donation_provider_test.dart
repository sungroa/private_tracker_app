import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/models/donation_product.dart';
import 'package:private_tracker_app/domain/repositories/donation_repository.dart';
import 'package:private_tracker_app/presentation/providers/donation_provider.dart';

class MockDonationRepository extends Mock implements IDonationRepository {}

void main() {
  late DonationProvider provider;
  late MockDonationRepository mockRepository;
  late StreamController<bool> supporterStreamController;

  setUp(() {
    mockRepository = MockDonationRepository();
    supporterStreamController = StreamController<bool>.broadcast();

    when(
      () => mockRepository.isSupporterStream,
    ).thenAnswer((_) => supporterStreamController.stream);
    when(() => mockRepository.isSupporter()).thenAnswer((_) async => false);
    when(() => mockRepository.getDonationProducts()).thenAnswer((_) async => []);
  });

  void initProvider() {
    provider = DonationProvider(mockRepository);
  }

  tearDown(() {
    supporterStreamController.close();
  });

  group('DonationProvider Tests', () {
    test('initialization should load products', () async {
      final mockProducts = [
        const DonationProduct(
          id: '1',
          name: 'P1',
          description: '...',
          formattedPrice: '\$1',
          isSubscription: false,
        ),
      ];
      when(() => mockRepository.getDonationProducts()).thenAnswer((_) async => mockProducts);

      initProvider();

      // Wait for all async init tasks to complete
      await pumpEventQueue();

      expect(provider.products, mockProducts);
      expect(provider.isLoading, isFalse);
    });

    test('loadProducts should update products and clear loading state', () async {
      final mockProducts = [
        const DonationProduct(
          id: '1',
          name: 'P1',
          description: '...',
          formattedPrice: '\$1',
          isSubscription: false,
        ),
      ];
      when(() => mockRepository.getDonationProducts()).thenAnswer((_) async => mockProducts);

      initProvider();
      await provider.loadProducts();

      expect(provider.products, mockProducts);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('loadProducts should set error if repository returns empty list', () async {
      when(() => mockRepository.getDonationProducts()).thenAnswer((_) async => []);

      initProvider();
      await provider.loadProducts();

      expect(provider.products, isEmpty);
      expect(provider.error, isNotNull);
    });

    test('purchase should set error if repository fails', () async {
      const product = DonationProduct(
        id: '1',
        name: 'P1',
        description: '...',
        formattedPrice: '\$1',
        isSubscription: false,
      );
      when(() => mockRepository.purchase(product)).thenAnswer((_) async => false);

      initProvider();
      await provider.purchase(product);

      expect(provider.error, contains('could not be completed'));
      expect(provider.isLoading, isFalse);
    });

    test('supporter stream updates should update provider state', () async {
      initProvider();
      supporterStreamController.add(true);

      // Wait for stream listener to trigger
      await pumpEventQueue();

      expect(provider.isSupporter, isTrue);
    });
  });
}
