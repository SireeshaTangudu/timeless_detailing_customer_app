import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';

class BookingsController extends ChangeNotifier {
  final BaseOdooService _odooService;

  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  BookingsController(this._odooService) {
    loadBookings();
  }

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bookings = await _odooService.getBookings('res_partner_12');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load detailing bookings from Odoo.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Booking?> scheduleBooking({
    required DetailService service,
    required String vehicleName,
    required String vehiclePlate,
    required DateTime dateTime,
    required String notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Local simulated delay for smooth button feedback
    await Future.delayed(const Duration(milliseconds: 300));

    final localBooking = Booking(
      id: 'SO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      service: service,
      vehicleName: vehicleName,
      vehicleLicensePlate: vehiclePlate,
      bookingDateTime: dateTime,
      status: BookingStatus.confirmed,
      currentStep: 0,
      totalPrice: service.price > 0 ? service.price : 2800.0,
      notes: notes,
      beforeImages: [],
      afterImages: [],
      technicianName: 'Marcus Vance',
      technicianAvatar: '',
    );

    // Insert into local bookings list for UI testing
    _bookings.insert(0, localBooking);
    _isLoading = false;
    notifyListeners();

    return localBooking;
  }
}
