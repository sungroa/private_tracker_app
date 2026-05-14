import 'package:flutter/material.dart';
import '../../domain/models/donation_product.dart';
import '../../domain/repositories/donation_repository.dart';

/// Manages the state for the donation flow.
class DonationProvider extends ChangeNotifier {
  final IDonationRepository _repository;

  List<DonationProduct> _products = [];
  bool _isLoading = false;
  bool _isSupporter = false;
  String? _error;

  DonationProvider(this._repository) {
    _init();
  }

  List<DonationProduct> get products => _products;
  bool get isLoading => _isLoading;
  bool get isSupporter => _isSupporter;
  String? get error => _error;

  Future<void> _init() async {
    _repository.isSupporterStream.listen((status) {
      _isSupporter = status;
      notifyListeners();
    });
    _isSupporter = await _repository.isSupporter();
    await loadProducts();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _repository.getDonationProducts();
      if (_products.isEmpty) {
        _error = "Billing services are currently unavailable or the product catalog is empty.";
      }
    } catch (e) {
      _error = "Failed to load products. Please check your internet connection.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> purchase(DonationProduct product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.purchase(product);
      if (!success) {
        _error = "Purchase could not be completed.";
      }
    } catch (e) {
      _error = "An error occurred during the purchase.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.restorePurchases();
    } catch (e) {
      _error = "Failed to restore purchases.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
