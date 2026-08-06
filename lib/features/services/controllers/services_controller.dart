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
      imageUrl: 'assets/services/interior/interior_detailing.png',
      category: 'Interior',
      whatsIncluded: [
        'Carpets & Upholstery Deep Steam Cleaning',
        'Leather Conditioning & UV Protection Treatment',
        'Dashboard, Vents & Console Sanitization',
        'Door Jambs, Trim & Cup Holder Detailing',
        'Complete Odor Elimination & Air Refreshener',
      ],
      assetImagePath: 'assets/services/interior/interior_detailing.png',
    ),
    DetailService(
      id: '2',
      name: 'Paint Care',
      description:
          "Multi-stage paint refinement and high-gloss polishing treatment removing swirl marks, light scratches, and oxidation to restore mirror-like clarity and reflection to your vehicle's finish.",
      price: 299.0,
      durationHours: 4.0,
      assetImagePath: 'assets/services/paint_care/paint_care.png',

      category: 'Exterior',
      whatsIncluded: [
        'Clay Bar Decontamination & Iron Remover',
        'Single-Stage Dual-Action Machine Polish',
        'Paint Swirl & Light Scratch Reduction',
        'Hydrophobic Sealant Application',
        'Wheel & Tire Deep Clean & Dressing',
      ],
      imageUrl: 'assets/services/paint_care/paint_care.png',
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
        'High-Temp Wheel Ceramic Armor',
      ],
      assetImagePath: 'assets/services/protection/protection.png',
    ),
    DetailService(
      id: '4',
      name: 'Maintenance Membership',
      description:
          'Stay protected all year with unlimited monthly maintenance washes, priority booking, exclusive member discounts on advanced treatments, and loyalty points that earn free upgrades and seasonal perks.',
      price: 89.0,
      durationHours: 0.0,
      imageUrl:
          'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?w=800&auto=format&fit=crop&q=80',
      category: 'Memberships',
      whatsIncluded: [
        '2 x Maintenance Washes Per Month',
        '10% Off All Detailing Services',
        'Priority Booking & Holiday Slots',
        'Quarterly Interior Sanitization',
        'Exclusive Member Loyalty Rewards',
      ],
      assetImagePath: 'assets/services/maintenance/maintenance_membership.png',
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
