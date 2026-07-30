import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';

class ServicesController extends ChangeNotifier {
  final BaseOdooService _odooService;

  static final List<DetailService> defaultServices = const [
    DetailService(
      id: '1',
      name: 'Interior Detailing',
      description:
          "Your vehicle's interior is where you spend your time on every journey, and it deserves the same level of care as the exterior. Our Interior Detail is a comprehensive restoration service designed to safely clean, sanitize, and rejuvenate every interior surface while preserving the original materials.\n\nUsing professional techniques and premium products, we meticulously clean carpets, upholstery, leather, plastics, trim, vents, cup holders, door headlining, and all interior touchpoints carefully addressed to restore a clean, refined cabin environment.",
      price: 199.0,
      durationHours: 3.5,
      imageUrl:
          'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?w=800&auto=format&fit=crop&q=80',
      category: 'Interior',
      whatsIncluded: [
        'Carpets & Upholstery Deep Steam Cleaning',
        'Leather Conditioning & UV Protection Treatment',
        'Dashboard, Vents & Console Sanitization',
        'Door Jambs, Trim & Cup Holder Detailing',
        'Complete Odor Elimination & Air Refreshener'
      ],
    ),
    DetailService(
      id: '2',
      name: 'Paint Care',
      description:
          "Multi-stage paint refinement and high-gloss polishing treatment removing swirl marks, light scratches, and oxidation to restore mirror-like clarity and reflection to your vehicle's finish.",
      price: 299.0,
      durationHours: 4.0,
      imageUrl:
          'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=800&auto=format&fit=crop&q=80',
      category: 'Exterior',
      whatsIncluded: [
        'Clay Bar Decontamination & Iron Remover',
        'Single-Stage Dual-Action Machine Polish',
        'Paint Swirl & Light Scratch Reduction',
        'Hydrophobic Sealant Application',
        'Wheel & Tire Deep Clean & Dressing'
      ],
    ),
    DetailService(
      id: '3',
      name: 'Protection',
      description:
          'Our premier maintenance programme for owners who expect their vehicles to remain in exceptional condition all year round with nano-ceramic hydrophobic protection.',
      price: 599.0,
      durationHours: 6.0,
      imageUrl:
          'https://images.unsplash.com/photo-1603584173870-7f23fdae1b7a?w=800&auto=format&fit=crop&q=80',
      category: 'Protection',
      whatsIncluded: [
        '9H Professional Ceramic Coating (3-Year Shield)',
        'Front Bumper & Hood Paint Protection Film',
        'Glass Hydrophobic Rain Shield Coating',
        'High-Temp Wheel Ceramic Armor'
      ],
    ),
  ];

  List<DetailService> _services = List.from(defaultServices);
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
      final fetched = await _odooService.getServices();
      if (fetched.isNotEmpty) {
        _services = fetched;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Keep static default services so app stays functional while Odoo API is offline
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }
}
