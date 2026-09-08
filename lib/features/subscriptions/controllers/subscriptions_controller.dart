import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/subscriptions/models/subscription_model.dart';

class SubscriptionsController extends ChangeNotifier {
  final BaseOdooService _odooService;

  List<SubscriptionModel> _subscriptions = [];
  bool _isLoading = false;
  String? _errorMessage;

  SubscriptionsController(this._odooService) {
    loadSubscriptions();
  }

  List<SubscriptionModel> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSubscriptions({int? partnerId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final listMap = await _odooService.getSubscriptions(partnerId: partnerId);
      _subscriptions = listMap.map((map) => SubscriptionModel.fromJson(map)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('SubscriptionsController loadSubscriptions error: $e');
      _errorMessage = 'Failed to load subscriptions.';
      _subscriptions = [];
      _isLoading = false;
      notifyListeners();
    }
  }
}
