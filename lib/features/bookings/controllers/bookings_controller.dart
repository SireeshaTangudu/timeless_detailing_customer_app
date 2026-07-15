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

    try {
      final placeholderBooking = Booking(
        id: '',
        service: service,
        vehicleName: vehicleName,
        vehicleLicensePlate: vehiclePlate,
        bookingDateTime: dateTime,
        status: BookingStatus.confirmed,
        currentStep: 0,
        totalPrice: service.price,
        notes: notes,
        beforeImages: [],
        afterImages: [],
        technicianName: 'Marcus Vance',
        technicianAvatar: '',
      );

      final created = await _odooService.createBooking(placeholderBooking);
      
      // Update local list
      _bookings.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = 'Failed to create booking in Odoo.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
