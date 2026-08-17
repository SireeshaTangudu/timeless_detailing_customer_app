import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_variant_model.dart';
import 'package:timeless_detailing_customer_app/features/services/models/product_category_model.dart';

class ServicesController extends ChangeNotifier {
  final BaseOdooService _odooService;

  List<DetailService> _services = [];
  List<ProductCategory> _productCategories = [];
  final Map<int, List<ProductVariant>> _serviceVariants = {};
  bool _isLoading = false;
  String _selectedCategory = 'All';
  int? _selectedCategoryId;
  String? _errorMessage;

  ServicesController(this._odooService) {
    initData();
  }

  List<DetailService> get services => _services;
  List<ProductCategory> get productCategories => _productCategories;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get errorMessage => _errorMessage;

  List<String> get categories {
    if (_productCategories.isNotEmpty) {
      final names = _productCategories.map((c) => c.name).toList();
      names.insert(0, 'All');
      return names;
    }
    final list = _services.map((s) => s.category).toSet().toList();
    list.insert(0, 'All');
    return list;
  }

  List<DetailService> get filteredServices {
    if (_selectedCategory == 'All') {
      return _services;
    }
    return _services.where((s) {
      if (_selectedCategoryId != null && s.mobileCategoryId != null) {
        return s.mobileCategoryId == _selectedCategoryId;
      }
      return s.category == _selectedCategory;
    }).toList();
  }

  Future<void> initData() async {
    await fetchProductCategories();
    await loadServices();
  }

  /// Fetch Categories from timeless.product.category
  Future<void> fetchProductCategories() async {
    try {
      final cats = await _odooService.getProductCategories();
      if (cats.isNotEmpty) {
        _productCategories = cats;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('🔴 [ServicesController] Error fetching categories: $e');
    }
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    if (category == 'All') {
      _selectedCategoryId = null;
    } else {
      final matchedCat = _productCategories.firstWhere(
        (c) => c.name == category,
        orElse: () => ProductCategory(id: 0, name: category),
      );
      _selectedCategoryId = matchedCat.id != 0 ? matchedCat.id : null;
    }
    notifyListeners();
    loadServices(categoryId: _selectedCategoryId);
  }

  void selectCategoryById(int? categoryId, String categoryName) {
    _selectedCategoryId = categoryId;
    _selectedCategory = categoryName;
    notifyListeners();
    loadServices(categoryId: _selectedCategoryId);
  }

  /// Endpoint 1 & 3: Get Main Services (optionally filtered by mobile_categ_id)
  Future<void> loadServices({int? categoryId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint('🔵 [ServicesController] Triggering loadServices from Odoo API (catId=$categoryId)...');

    try {
      final fetched = await _odooService.getServicesFromProductTemplate(categoryId: categoryId);
      debugPrint('🟢 [ServicesController] Successfully loaded ${fetched.length} services from Odoo');
      if (categoryId == null || _services.isEmpty) {
        _services = fetched;
      } else {
        // Update or replace existing services
        final fetchedIds = fetched.map((s) => s.id).toSet();
        _services = [
          ...fetched,
          ..._services.where((s) => !fetchedIds.contains(s.id)),
        ];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('🔴 [ServicesController] Error in loadServices: $e');
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

