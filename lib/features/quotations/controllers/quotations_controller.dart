import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/quotations/models/quotation_model.dart';

class QuotationsController extends ChangeNotifier {
  final BaseOdooService _odooService;

  List<QuotationModel> _quotations = [];
  bool _isLoading = false;
  String? _errorMessage;

  QuotationsController(this._odooService) {
    loadQuotations();
  }

  List<QuotationModel> get quotations => _quotations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadQuotations({int? partnerId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final listMap = await _odooService.getQuotations(partnerId: partnerId);
      _quotations = listMap.map((map) => QuotationModel.fromJson(map)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('QuotationsController loadQuotations error: $e');
      _errorMessage = 'Failed to load quotations.';
      _quotations = [];
      _isLoading = false;
      notifyListeners();
    }
  }
}
