import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/core/network/mock_odoo_service.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';

class TrackingController extends ChangeNotifier {
  final BaseOdooService _odooService;
  final BookingsController _bookingsController;

  Booking? _trackedBooking;
  bool _isLoading = false;

  TrackingController(this._odooService, this._bookingsController);

  Booking? get trackedBooking => _trackedBooking;
  bool get isLoading => _isLoading;

  Future<void> fetchTrackingStatus(String bookingId) async {
    _isLoading = true;
    notifyListeners();

    _trackedBooking = await _odooService.getLiveTrackingBooking(bookingId);
    _isLoading = false;
    notifyListeners();
  }

  // Simulation method: Advances the status of the booking in mock database
  // to allow the user to preview how Odoo status transitions affect the client app.
  void simulateNextStatusStep() {
    if (_trackedBooking == null) return;
    if (_odooService is MockOdooService) {
      BookingStatus nextStatus;
      switch (_trackedBooking!.status) {
        case BookingStatus.confirmed:
          nextStatus = BookingStatus.received;
          break;
        case BookingStatus.received:
          nextStatus = BookingStatus.inProgress;
          break;
        case BookingStatus.inProgress:
          nextStatus = BookingStatus.ready;
          break;
        case BookingStatus.ready:
          nextStatus = BookingStatus.completed;
          break;
        case BookingStatus.completed:
          nextStatus = BookingStatus.confirmed; // reset cycle for loop testing
          break;
      }
      _odooService.updateMockBookingStatus(_trackedBooking!.id, nextStatus);
      
      // Reload states in both controllers
      _bookingsController.loadBookings();
      fetchTrackingStatus(_trackedBooking!.id);
    }
  }
}
