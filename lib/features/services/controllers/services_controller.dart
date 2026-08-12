import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_variant_model.dart';

class ServicesController extends ChangeNotifier {
  final BaseOdooService _odooService;

  List<DetailService> _services = [];
  final Map<int, List<ProductVariant>> _serviceVariants = {};
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

  List<String> get categories {
    final list = _services.map((s) => s.category).toSet().toList();
    list.insert(0, 'All');
    return list;
  }

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

  /// Endpoint 1: Get Main Services
  Future<void> loadServices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint('🔵 [ServicesController] Triggering loadServices from Odoo API...');

    try {
      final fetched = await _odooService.getServicesFromProductTemplate();
      debugPrint('🟢 [ServicesController] Successfully loaded ${fetched.length} services from Odoo');
      _services = fetched;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('🔴 [ServicesController] Error in loadServices: $e');
      _services = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Endpoint 2: Get Service Details with Variants
  Future<List<ProductVariant>> fetchVariants(int templateId) async {
    if (_serviceVariants.containsKey(templateId)) {
      return _serviceVariants[templateId]!;
    }
    try {
      final variants = await _odooService.getServiceDetailsWithVariants(templateId);
      _serviceVariants[templateId] = variants;
      notifyListeners();
      return variants;
    } catch (e) {
      return [];
    }
  }

  List<ProductVariant> getVariantsForTemplate(int templateId) {
    return _serviceVariants[templateId] ?? [];
  }
}
