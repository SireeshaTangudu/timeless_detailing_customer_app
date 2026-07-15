import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';

class MockOdooService implements BaseOdooService {
  // Mock In-Memory Data Store
  final List<DetailService> _mockServices = [
    const DetailService(
      id: 'srv_1',
      name: 'Exterior Wash & Wax',
      description: 'A premium exterior cleaning including iron decontamination, clay bar wash, and long-lasting synthetic spray wax application.',
      price: 99.99,
      durationHours: 1.5,
      imageUrl: 'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?w=500&auto=format&fit=crop&q=60',
      category: 'Exterior Details',
      whatsIncluded: [
        'Pre-wash foam bath & rinse',
        'Two-bucket scratch-free hand wash',
        'Iron fallout remover & clay bar paint treatment',
        'Premium synthetic spray wax (up to 3 months protection)',
        'Rims polished & tires dressed',
        'Streak-free exterior glass cleaning',
      ],
      odooProductId: 101,
    ),
    const DetailService(
      id: 'srv_2',
      name: 'Interior Deep Clean',
      description: 'Complete interior restoration. Includes deep carpet extraction, leather conditioning, steam sanitization, and dashboard UV protection.',
      price: 149.99,
      durationHours: 2.5,
      imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&auto=format&fit=crop&q=60',
      category: 'Interior Details',
      whatsIncluded: [
        'Detailed vacuuming of seats, carpet & trunk',
        'Hot water extraction on carpet & fabric mats',
        'Leather upholstery deep clean & conditioning',
        'Steam cleaning & disinfection of all surfaces',
        'Dashboard, console & door panels UV protectant',
        'Streak-free interior glass cleaning & scent spray',
      ],
      odooProductId: 102,
    ),
    const DetailService(
      id: 'srv_3',
      name: 'Signature Paint Correction',
      description: 'Single-stage machine polishing to eliminate 60-70% of light swirl marks and scratches, restoring a deep high-gloss mirror finish.',
      price: 299.99,
      durationHours: 4.0,
      imageUrl: 'https://images.unsplash.com/photo-1507136566006-cfc505b114fc?w=500&auto=format&fit=crop&q=60',
      category: 'Signature Packages',
      whatsIncluded: [
        'Multi-stage foam wash & complete paint decontamination',
        'Tape-off of all rubber trim, plastics, and sensitive edges',
        'Single-stage machine polish compound application',
        'Premium hybrid ceramic sealant (up to 6 months protection)',
        'Full engine bay detailing and dressing',
        'Complimentary interior vacuum & wipe-down',
      ],
      odooProductId: 103,
    ),
    const DetailService(
      id: 'srv_4',
      name: 'Complete Ceramic Coating Gold',
      description: 'Multi-stage paint correction followed by professional-grade 9H Ceramic Coating. Offers ultimate paint protection, hydrophobicity, and deep gloss.',
      price: 599.99,
      durationHours: 6.0,
      imageUrl: 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=500&auto=format&fit=crop&q=60',
      category: 'Ceramic Coatings',
      whatsIncluded: [
        'Decontamination wash & multi-stage paint correction (removing 85%+ defects)',
        'Alcohol wipe-down to prep paint surface',
        'Dual-layer professional 9H Nano Ceramic Coating on all paint',
        'Ceramic wheel face coating & glass rain-repellent coating',
        'Trim restoration & plastic ceramic coating',
        '5-Year warranty certificate registered in our system',
      ],
      odooProductId: 104,
    ),
  ];

  final List<Booking> _mockBookings = [];
  Map<String, dynamic>? _mockProfile;

  MockOdooService() {
    // Populate an active default booking for demonstration
    final now = DateTime.now();
    _mockBookings.add(
      Booking(
        id: 'bk_982',
        service: _mockServices[2], // Signature Paint Correction
        vehicleName: 'Porsche 911 GT3 (992)',
        vehicleLicensePlate: 'TIMELESS-1',
        bookingDateTime: now.subtract(const Duration(hours: 2)),
        status: BookingStatus.inProgress,
        currentStep: 2, // Cleaning & Paint Prep phase
        totalPrice: 299.99,
        notes: 'Please pay extra attention to the rear spoiler. Looking forward to the results!',
        beforeImages: [
          'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?w=500&auto=format&fit=crop&q=60',
          'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=500&auto=format&fit=crop&q=60',
        ],
        afterImages: [],
        technicianName: 'Marcus Vance (Master Detailer)',
        technicianAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=60',
        odooSaleOrderId: 982,
      ),
    );

    // Populate a history booking (completed)
    _mockBookings.add(
      Booking(
        id: 'bk_712',
        service: _mockServices[1], // Interior Deep Clean
        vehicleName: 'Tesla Model S Plaid',
        vehicleLicensePlate: 'E-SPEED-9',
        bookingDateTime: now.subtract(const Duration(days: 12)),
        status: BookingStatus.completed,
        currentStep: 4,
        totalPrice: 149.99,
        notes: 'Needs coffee stain removal on driver armrest.',
        beforeImages: [
          'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&auto=format&fit=crop&q=60',
        ],
        afterImages: [
          'https://images.unsplash.com/photo-1617788138017-80ad40651399?w=500&auto=format&fit=crop&q=60',
        ],
        technicianName: 'Marcus Vance',
        technicianAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=60',
        odooSaleOrderId: 712,
      ),
    );

    _mockProfile = {
      'id': 'res_partner_12',
      'name': 'Alex Sterling',
      'email': 'alex.sterling@example.com',
      'phone': '+1 (555) 019-2834',
      'street': '742 Beverly Blvd',
      'city': 'Los Angeles',
      'zip': '90210',
      'loyalty_points': 450,
      'member_since': 'October 2025',
    };
  }

  @override
  Future<bool> login(String email, String password) async {
    // Simple mock logic - allow login for valid email format
    await Future.delayed(const Duration(milliseconds: 1200));
    if (email.contains('@') && password.length >= 4) {
      _mockProfile = {
        'id': 'res_partner_12',
        'name': email.split('@')[0].toUpperCase(),
        'email': email,
        'phone': '+1 (555) 019-2834',
        'street': '742 Beverly Blvd',
        'city': 'Los Angeles',
        'zip': '90210',
        'loyalty_points': 120,
        'member_since': 'July 2026',
      };
      return true;
    }
    return false;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<List<DetailService>> getServices() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockServices;
  }

  @override
  Future<List<Booking>> getBookings(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockBookings;
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    // Generate mock order and prepend to booking history
    final newBooking = booking.copyWith(
      id: 'bk_${_mockBookings.length + 800}',
      odooSaleOrderId: _mockBookings.length + 800,
      status: BookingStatus.confirmed,
      currentStep: 0,
      technicianName: 'Marcus Vance',
      technicianAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=60',
    );
    _mockBookings.insert(0, newBooking);

    // Add mock points
    if (_mockProfile != null) {
      _mockProfile!['loyalty_points'] = (_mockProfile!['loyalty_points'] ?? 0) + 100;
    }
    return newBooking;
  }

  @override
  Future<Booking?> getLiveTrackingBooking(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _mockBookings.firstWhere((b) => b.id == bookingId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCustomerProfile(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockProfile;
  }

  @override
  Future<bool> signup(String name, String email, String phone, String password) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return email.contains('@') && password.length >= 4;
  }

  @override
  Future<bool> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return email.contains('@');
  }

  // Helper method for the demo: allows updating the status of an active booking 
  // so the user can see real-time UI changes in the live-tracking panel.
  void updateMockBookingStatus(String bookingId, BookingStatus newStatus) {
    final index = _mockBookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final old = _mockBookings[index];
      int step = 0;
      switch (newStatus) {
        case BookingStatus.confirmed:
          step = 0;
          break;
        case BookingStatus.received:
          step = 1;
          break;
        case BookingStatus.inProgress:
          step = 2;
          break;
        case BookingStatus.ready:
          step = 3;
          break;
        case BookingStatus.completed:
          step = 4;
          break;
      }
      
      // Simulate adding finished pics when ready
      List<String> after = [];
      if (newStatus == BookingStatus.ready || newStatus == BookingStatus.completed) {
        after = [
          'https://images.unsplash.com/photo-1617788138017-80ad40651399?w=500&auto=format&fit=crop&q=60',
          'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=500&auto=format&fit=crop&q=60'
        ];
      }

      _mockBookings[index] = old.copyWith(
        status: newStatus,
        currentStep: step,
        afterImages: after,
      );
    }
  }
}
