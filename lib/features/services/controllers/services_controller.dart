import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const String _kCachedCategoriesKey = 'cached_product_categories';
  static const String _kCachedServicesPrefix = 'cached_services_cat_';
  static const String _kCachedVariantsPrefix = 'cached_variants_tpl_';

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
    if (_selectedCategory == 'All' || _selectedCategory.isEmpty) {
      return _services;
    }
    
    if (_selectedCategoryId != null && _services.isNotEmpty) {
      final categoryMatched = _services.where((s) {
        if (s.mobileCategoryId != null && s.mobileCategoryId! > 0) {
          return s.mobileCategoryId == _selectedCategoryId;
        }
        return true;
      }).toList();
      if (categoryMatched.isNotEmpty) return categoryMatched;
      return _services;
    }

    final filtered = _services.where((s) {
      final cat = s.category.toLowerCase().trim();
      final sel = _selectedCategory.toLowerCase().trim();
      return cat == sel ||
          cat.contains(sel) ||
          sel.contains(cat) ||
          (sel.contains('package') && cat.contains('package')) ||
          (sel.contains('ceramic') && cat.contains('ceramic')) ||
          (sel.contains('paint') && cat.contains('paint')) ||
          (sel.contains('tint') && cat.contains('tint')) ||
          (sel.contains('interior') && cat.contains('interior'));
    }).toList();

    return filtered;
  }

  Future<void> initData() async {
    // 1. Instantly load cached categories and services from disk (0ms UI paint)
    await _loadCachedCategories();
    await _loadCachedServices(categoryId: _selectedCategoryId);

    // If no cache exists (e.g. first-time logged-in user), show loading state
    if (_productCategories.isEmpty || _services.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    // 2. Fetch fresh data from Odoo API
    await Future.wait([
      fetchProductCategories(),
      loadServices(categoryId: _selectedCategoryId, isBackgroundRefresh: true),
    ]);
  }

  /// Load cached product categories from SharedPreferences
  Future<void> _loadCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCachedCategoriesKey);
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw);
        _productCategories = list
            .whereType<Map<String, dynamic>>()
            .map((json) => ProductCategory.fromJson(json))
            .toList();
        if (_productCategories.isNotEmpty) {
          debugPrint('⚡ [ServicesController] Loaded ${_productCategories.length} categories from cache');
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ServicesController] Error reading cached categories: $e');
    }
  }

  /// Save product categories to SharedPreferences
  Future<void> _saveCachedCategories(List<ProductCategory> cats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = cats.map((c) => c.toJson()).toList();
      await prefs.setString(_kCachedCategoriesKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('⚠️ [ServicesController] Error saving categories to cache: $e');
    }
  }

  /// Load cached services for categoryId from SharedPreferences
  Future<void> _loadCachedServices({int? categoryId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_kCachedServicesPrefix${categoryId ?? 0}';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw);
        final cached = list
            .whereType<Map<String, dynamic>>()
            .map((json) => DetailService.fromCacheMap(json))
            .toList();
        if (cached.isNotEmpty) {
          _services = cached;
          _isLoading = false;
          debugPrint('⚡ [ServicesController] Loaded ${_services.length} services from cache (catId=$categoryId)');
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ServicesController] Error reading cached services: $e');
    }
  }

  /// Save services to SharedPreferences
  Future<void> _saveCachedServices({int? categoryId, required List<DetailService> servicesList}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_kCachedServicesPrefix${categoryId ?? 0}';
      final jsonList = servicesList.map((s) => s.toCacheMap()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('⚠️ [ServicesController] Error saving services to cache: $e');
    }
  }

  /// Fetch Categories from timeless.product.category
  Future<void> fetchProductCategories() async {
    if (_productCategories.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final cats = await _odooService.getProductCategories();
      if (cats.isNotEmpty) {
        _productCategories = cats;
        _saveCachedCategories(cats);
      }
    } catch (e) {
      debugPrint('🔴 [ServicesController] Error fetching categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    if (category == 'All') {
      _selectedCategoryId = null;
    } else {
      final matchedCat = _productCategories.firstWhere(
        (c) {
          final cName = c.name.toLowerCase().trim();
          final selName = category.toLowerCase().trim();
          return cName == selName || cName.contains(selName) || selName.contains(cName);
        },
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
  Future<void> loadServices({int? categoryId, bool isBackgroundRefresh = false}) async {
    // 1. Check local cache first if not background refresh
    if (!isBackgroundRefresh) {
      await _loadCachedServices(categoryId: categoryId);
    }

    // If we have cached services, keep showing them while updating in background
    if (_services.isEmpty) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    debugPrint('🔵 [ServicesController] Fetching fresh services from Odoo API (catId=$categoryId)...');

    try {
      final fetched = await _odooService.getServicesFromProductTemplate(categoryId: categoryId);
      debugPrint('🟢 [ServicesController] Successfully loaded ${fetched.length} services from Odoo');
      _services = fetched;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      _saveCachedServices(categoryId: categoryId, servicesList: fetched);
    } catch (e) {
      debugPrint('🔴 [ServicesController] Error in loadServices: $e');
      _isLoading = false;
      if (_services.isEmpty) {
        _errorMessage = 'Failed to load services';
      }
      notifyListeners();
    }
  }

  /// Endpoint 2: Get Service Details with Variants
  Future<List<ProductVariant>> fetchVariants(int templateId) async {
    // 1. Check in-memory cache first
    if (_serviceVariants.containsKey(templateId) && _serviceVariants[templateId]!.isNotEmpty) {
      return _serviceVariants[templateId]!;
    }

    // 2. Check disk cache
    final diskCached = await _loadCachedVariants(templateId);
    if (diskCached.isNotEmpty) {
      _serviceVariants[templateId] = diskCached;
      notifyListeners();
      // Fetch fresh in background
      _fetchFreshVariants(templateId);
      return diskCached;
    }

    // 3. Fetch from API if no cache exists
    return _fetchFreshVariants(templateId);
  }

  Future<List<ProductVariant>> _fetchFreshVariants(int templateId) async {
    try {
      final variants = await _odooService.getServiceDetailsWithVariants(templateId);
      if (variants.isNotEmpty) {
        _serviceVariants[templateId] = variants;
        notifyListeners();
        _saveCachedVariants(templateId, variants);
      }
      return variants;
    } catch (e) {
      debugPrint('⚠️ [ServicesController] Error fetching variants for templateId=$templateId: $e');
      return _serviceVariants[templateId] ?? [];
    }
  }

  Future<List<ProductVariant>> _loadCachedVariants(int templateId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_kCachedVariantsPrefix$templateId';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw);
        return list
            .whereType<Map<String, dynamic>>()
            .map((json) => ProductVariant.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('⚠️ [ServicesController] Error reading cached variants: $e');
    }
    return [];
  }

  Future<void> _saveCachedVariants(int templateId, List<ProductVariant> variants) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_kCachedVariantsPrefix$templateId';
      final jsonList = variants.map((v) => v.toJson()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('⚠️ [ServicesController] Error saving variants to cache: $e');
    }
  }

  List<ProductVariant> getVariantsForTemplate(int templateId) {
    return _serviceVariants[templateId] ?? [];
  }

  ProductVariant? findVariantByProductId(int? productId) {
    if (productId == null) return null;
    for (final varList in _serviceVariants.values) {
      for (final v in varList) {
        if (v.id == productId) return v;
      }
    }
    return null;
  }

  Future<ProductVariant?> fetchVariantById(int productId) async {
    final existing = findVariantByProductId(productId);
    if (existing != null) return existing;
    try {
      final variant = await _odooService.getVariantById(productId);
      return variant;
    } catch (e) {
      return null;
    }
  }
}
