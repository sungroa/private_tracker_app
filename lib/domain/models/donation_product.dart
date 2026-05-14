import 'package:meta/meta.dart';

/// Represents a product available for donation.
@immutable
class DonationProduct {
  /// Unique identifier of the product in the Play Store.
  final String id;

  /// User-friendly name of the product.
  final String name;

  /// detailed description of the product.
  final String description;

  /// Formatted price (e.g., "$4.99").
  final String formattedPrice;

  /// Whether this is a recurring subscription or a one-time purchase.
  final bool isSubscription;

  const DonationProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.formattedPrice,
    required this.isSubscription,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DonationProduct &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          formattedPrice == other.formattedPrice &&
          isSubscription == other.isSubscription;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      formattedPrice.hashCode ^
      isSubscription.hashCode;
}
