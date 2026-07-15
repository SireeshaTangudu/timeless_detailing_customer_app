import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';

class ServicesController extends ChangeNotifier {
  final BaseOdooService _odooService;

  List<DetailService> _services = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';
  String? _errorMessage;

  ServicesController(this._odooService) {
    loadServices();
  }

  List<DetailService> get services => _services;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String? get errorMessage => _errorMessage;

  // List of unique categories available
  List<String> get categories {
    final list = _services.map((s) => s.category).toSet().toList();
    list.insert(0, 'All');
    return list;
  }

  // Filter services by category
  List<DetailService> get filteredServices {
    if (_selectedCategory == 'All') {
      return _services;
    }
    return _services.where((s) => s.category == _selectedCategory).toList();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadServices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _services = await _odooService.getServices();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load services catalog from Odoo.';
      _isLoading = false;
      notifyListeners();
    }
  }
}
