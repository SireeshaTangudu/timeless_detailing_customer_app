import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/bookable_slot_model.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';

class BookingsController extends ChangeNotifier {
  final BaseOdooService _odooService;

  List<Booking> _bookings = [];
  BookableSlotsResult? _currentBookableSlots;
  bool _isLoading = false;
  bool _isLoadingSlots = false;
  String? _errorMessage;

  BookingsController(this._odooService) {
    loadBookings();
  }

  List<Booking> get bookings => _bookings;
  BookableSlotsResult? get currentBookableSlots => _currentBookableSlots;
  bool get isLoading => _isLoading;
  bool get isLoadingSlots => _isLoadingSlots;
  String? get errorMessage => _errorMessage;
  int? get currentPartnerId => _odooService.currentPartnerId ?? _odooService.currentUid;

  /// Endpoint 5: Get User Bookings (`calendar.event/web_search_read`)
  Future<void> loadBookings({int? partnerId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final id = partnerId ?? _odooService.currentPartnerId ?? _odooService.currentUid;
    if (id == null) {
      _bookings = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final res = await _odooService.getUserBookings(id);
      final List records = res['records'] is List ? res['records'] as List : [];

      final List<Booking> fetchedBookings = [];
      for (var rec in records) {
        final map = Map<String, dynamic>.from(rec as Map);
        final apptType = map['appointment_type_id'];
        final apptResources = map['appointment_resource_ids'];
        String serviceName = map['name']?.toString() ?? 'Car Detailing';
        int apptTypeId = 1;

        if (apptResources is List && apptResources.isNotEmpty) {
          final firstRes = apptResources.first;
          if (firstRes is Map && firstRes['name'] != null) {
            serviceName = firstRes['name'].toString();
          } else if (firstRes is List && firstRes.length >= 2) {
            serviceName = firstRes[1].toString();
          }
        } else if (apptType is Map && apptType['name'] != null) {
          serviceName = apptType['name'].toString();
          if (apptType['id'] is int) apptTypeId = apptType['id'];
        } else if (apptType is List && apptType.length >= 2) {
          if (apptType[0] is int) apptTypeId = apptType[0];
          serviceName = apptType[1].toString();
        }

        final detailService = DetailService(
          id: apptTypeId.toString(),
          name: serviceName,
          description: '',
          price: 0.0,
          durationHours: (map['duration'] as num?)?.toDouble() ?? 1.0,
          imageUrl: '',
          category: 'Detailing',
          whatsIncluded: [],
        );
        fetchedBookings.add(Booking.fromOdooJson(map, detailService));
      }
      _bookings = fetchedBookings;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('loadBookings error: $e');
      _errorMessage = 'Failed to load bookings.';
      _bookings = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Endpoint 3: Get Bookable Slots (`appointment.type/get_bookable_slots`)
  Future<List<BookableSlot>> fetchBookableSlots({
    required int appointmentTypeId,
    required String timezone,
    required int resourceId,
    required DateTime date,
  }) async {
    _isLoadingSlots = true;
    notifyListeners();

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final res = await _odooService.getBookableSlots(
      appointmentTypeId: appointmentTypeId,
      timezone: timezone,
      resourceId: resourceId,
      askedCapacity: 1,
      date: dateStr,
    );

    _currentBookableSlots = res;
    _isLoadingSlots = false;
    notifyListeners();

    return res?.slots ?? [];
  }

  /// Endpoint 4: Book Appointment (`calendar.event/web_save`)
  Future<Booking?> scheduleAppointment({
    required DetailService service,
    required int appointmentTypeId,
    int? productId,
    required DateTime startDateTime,
    required DateTime stopDateTime,
    required String vehicleMake,
    required String vehicleModel,
    required String vehiclePlate,
    required String phone,
    String? collectorName,
    String? collectorLicense,
    int? resourceId,
    List<String>? vehicleImagesBase64,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final bookerId = _odooService.currentUid ?? 65;
    final partnerId = _odooService.currentPartnerId ?? 14;
    final effectiveResourceId = resourceId ?? service.appointmentResourceId;
    final effectiveProductId = productId ?? service.odooProductId;

    final startStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(startDateTime);
    final stopStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(stopDateTime);
    final bookingName = '${service.name} - $vehicleMake $vehicleModel';

    try {
      final res = await _odooService.bookAppointment(
        name: bookingName,
        appointmentTypeId: appointmentTypeId,
        productId: effectiveProductId,
        appointmentBookerId: bookerId,
        partnerIds: [partnerId],
        start: startStr,
        stop: stopStr,
        duration: service.durationHours > 0 ? service.durationHours : 1.0,
        resourceId: effectiveResourceId,
        phone: phone,
        collectorName: collectorName,
        collectorLicense: collectorLicense,
        vehicleMake: vehicleMake,
        vehicleModel: vehicleModel,
        vehicleImagesBase64: vehicleImagesBase64,
      );

      Booking booking;
      if (res != null) {
        booking = Booking.fromOdooJson(res, service);
      } else {
        booking = Booking(
          id: 'SO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          service: service,
          vehicleName: '$vehicleMake $vehicleModel',
          vehicleLicensePlate: vehiclePlate,
          bookingDateTime: startDateTime,
          status: BookingStatus.confirmed,
          currentStep: 0,
          totalPrice: service.price,
          notes: 'Phone: $phone',
          beforeImages: [],
          afterImages: [],
          technicianName: collectorName ?? 'Lead Detailer',
          technicianAvatar: '',
        );
      }

      _bookings.insert(0, booking);
      _isLoading = false;
      notifyListeners();
      return booking;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Booking failed: $e';
      notifyListeners();
      return null;
    }
  }

  /// Endpoint 6: Get Specific Booking Details (`calendar.event/web_read`)
  Future<Booking?> fetchBookingDetails(int bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _odooService.getBookingDetails(bookingId);
      if (res != null) {
        final apptType = res['appointment_type_id'];
        final apptResources = res['appointment_resource_ids'];
        String serviceName = 'Car Detailing';
        int apptTypeId = 1;

        if (apptResources is List && apptResources.isNotEmpty) {
          final firstRes = apptResources.first;
          if (firstRes is Map && firstRes['name'] != null) {
            serviceName = firstRes['name'].toString();
          } else if (firstRes is List && firstRes.length >= 2) {
            serviceName = firstRes[1].toString();
          }
        }

        if (serviceName == 'Car Detailing') {
          if (apptType is Map && apptType['name'] != null) {
            serviceName = apptType['name'].toString();
            if (apptType['id'] is int) apptTypeId = apptType['id'];
          } else if (apptType is List && apptType.length >= 2) {
            if (apptType[0] is int) apptTypeId = apptType[0];
            serviceName = apptType[1].toString();
          } else if (res['name'] != null) {
            serviceName = res['name'].toString();
          }
        }

        final detailService = DetailService(
          id: apptTypeId.toString(),
          name: serviceName,
          description: 'Scheduled detailing service',
          price: 150.0,
          durationHours: (res['duration'] as num?)?.toDouble() ?? 1.0,
          imageUrl: '',
          category: 'Detailing',
          whatsIncluded: [],
        );

        final booking = Booking.fromOdooJson(res, detailService);
        _isLoading = false;
        notifyListeners();
        return booking;
      }
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('fetchBookingDetails error: $e');
      _errorMessage = 'Failed to load booking details.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Endpoint 7: Cancel Booking (`calendar.event/action_cancel_meeting`)
  Future<bool> cancelBooking(int bookingId) async {
    _isLoading = true;
    notifyListeners();

    final partnerId = _odooService.currentPartnerId ?? _odooService.currentUid ?? 26;
    final res = await _odooService.cancelBooking(
      bookingId: bookingId,
      partnerIds: [partnerId],
    );

    if (res != null) {
      _bookings.removeWhere((b) => b.id == bookingId.toString() || b.odooSaleOrderId == bookingId);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
