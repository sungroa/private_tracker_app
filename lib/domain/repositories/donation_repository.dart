import '../models/donation_product.dart';

/// Interface for donation operations.
///
/// Completely abstracts the underlying billing platform (e.g., Google Play Billing).
abstract class IDonationRepository {
  /// Stream that emits true if the user is currently a "Supporter".
  ///
  /// This typically means they have an active subscription or have made a
  /// recent one-time donation.
  Stream<bool> get isSupporterStream;

  /// Fetches the list of products available for donation.
  Future<List<DonationProduct>> getDonationProducts();

  /// Initiates the purchase flow for a specific [product].
  ///
  /// Returns true if the purchase was successful.
  Future<bool> purchase(DonationProduct product);

  /// Restores previous purchases (primarily for subscriptions).
  Future<void> restorePurchases();

  /// Returns true if the user is currently a "Supporter".
  Future<bool> isSupporter();
}
