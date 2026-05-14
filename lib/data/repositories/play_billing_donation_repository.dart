import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../domain/models/donation_product.dart';
import '../../domain/repositories/donation_repository.dart';
import '../storage/secure_key_storage.dart';

/// Implementation of [IDonationRepository] using Google Play Billing.
class PlayBillingDonationRepository implements IDonationRepository {
  final SecureKeyStorage _keyStorage;
  final InAppPurchase _iap = InAppPurchase.instance;
  
  final StreamController<bool> _supporterController = StreamController<bool>.broadcast();
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  static const String _consumableId = 'tip_coffee_consumable';
  static const String _subscriptionId = 'support_monthly_tier1';
  static const Set<String> _productIds = {_consumableId, _subscriptionId};

  PlayBillingDonationRepository(this._keyStorage) {
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => _supporterController.addError(error),
    );
    _initSupporterStatus();
  }

  Future<void> _initSupporterStatus() async {
    final status = await isSupporter();
    _supporterController.add(status);
  }

  @override
  Stream<bool> get isSupporterStream => _supporterController.stream;

  @override
  Future<List<DonationProduct>> getDonationProducts() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint("PrivacyTracker.Donations: InAppPurchase is NOT available on this device.");
      return [];
    }

    final ProductDetailsResponse response = await _iap.queryProductDetails(_productIds);
    if (response.error != null) {
      debugPrint("PrivacyTracker.Donations: Failed to query products: ${response.error!.message}");
      return [];
    }

    if (response.productDetails.isEmpty) {
      debugPrint("PrivacyTracker.Donations: No products found for IDs: $_productIds. "
                 "Check if they are active in the Google Play Console.");
      return [];
    }

    return response.productDetails.map((pd) {
      return DonationProduct(
        id: pd.id,
        name: pd.title,
        description: pd.description,
        formattedPrice: pd.price,
        isSubscription: pd.id == _subscriptionId,
      );
    }).toList();
  }

  @override
  Future<bool> purchase(DonationProduct product) async {
    final ProductDetailsResponse response = await _iap.queryProductDetails({product.id});
    if (response.productDetails.isEmpty) return false;

    final productDetails = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: productDetails);

    if (product.isSubscription) {
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      return await _iap.buyConsumable(purchaseParam: purchaseParam);
    }
  }

  @override
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  @override
  Future<bool> isSupporter() async {
    return await _keyStorage.getSupporterStatus();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending state if needed
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        _handleSuccessfulPurchase(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    // In a real app, you should verify the purchase with your backend here.
    // Since this is a privacy-first app without a mandatory backend, we trust 
    // the Play Store response and persist locally.
    
    await _keyStorage.setSupporterStatus(true);
    _supporterController.add(true);
  }

  /// Disposes resources.
  void dispose() {
    _subscription.cancel();
    _supporterController.close();
  }
}
