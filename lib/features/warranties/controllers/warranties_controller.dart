import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/warranties/models/warranty_model.dart';

class WarrantiesController extends ChangeNotifier {
  final BaseOdooService _odooService;

  List<WarrantyModel> _warranties = [];
  bool _isLoading = false;
  String? _errorMessage;

  WarrantiesController(this._odooService) {
    loadWarranties();
  }

  List<WarrantyModel> get warranties => _warranties;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadWarranties({int? partnerId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final listMap = await _odooService.getWarranties(partnerId: partnerId);
      _warranties = listMap.map((map) => WarrantyModel.fromJson(map)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('WarrantiesController loadWarranties error: $e');
      _errorMessage = 'Failed to load warranties.';
      _warranties = [];
      _isLoading = false;
      notifyListeners();
    }
  }
}
