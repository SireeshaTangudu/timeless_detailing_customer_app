import 'package:flutter_test/flutter_test.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';

void main() {
  group('Booking.canCancel Tests', () {
    final mockService = const DetailService(
      id: '1',
      name: 'Ceramic Coating',
      description: 'Full body ceramic protection',
      price: 499.99,
      durationHours: 2.0,
      imageUrl: '',
      category: 'Detailing',
      whatsIncluded: [],
    );

    Booking createBooking({
      required BookingStatus status,
      required DateTime bookingDateTime,
    }) {
      return Booking(
        id: 'test_123',
        service: mockService,
        vehicleName: 'BMW M4',
        vehicleLicensePlate: 'TEST-123',
        bookingDateTime: bookingDateTime,
        status: status,
        currentStep: 0,
        totalPrice: 499.99,
        notes: 'Test booking',
        beforeImages: [],
        afterImages: [],
        technicianName: 'Marcus',
        technicianAvatar: '',
      );
    }

    test('Scenario 1: Confirmed booking with future date -> CAN cancel', () {
      final booking = createBooking(
        status: BookingStatus.confirmed,
        bookingDateTime: DateTime.now().add(const Duration(days: 2)),
      );

      expect(booking.canCancel, isTrue);
    });

    test('Scenario 2: Confirmed booking with past date -> CANNOT cancel', () {
      final booking = createBooking(
        status: BookingStatus.confirmed,
        bookingDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      );

      expect(booking.canCancel, isFalse);
    });

    test('Scenario 3: Car received at shop -> CANNOT cancel', () {
      final booking = createBooking(
        status: BookingStatus.received,
        bookingDateTime: DateTime.now().add(const Duration(days: 1)),
      );

      expect(booking.canCancel, isFalse);
    });

    test('Scenario 4: Detailing in progress -> CANNOT cancel', () {
      final booking = createBooking(
        status: BookingStatus.inProgress,
        bookingDateTime: DateTime.now().add(const Duration(hours: 4)),
      );

      expect(booking.canCancel, isFalse);
    });

    test('Scenario 5: Vehicle ready for pickup -> CANNOT cancel', () {
      final booking = createBooking(
        status: BookingStatus.ready,
        bookingDateTime: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(booking.canCancel, isFalse);
    });

    test('Scenario 6: Booking completed -> CANNOT cancel', () {
      final booking = createBooking(
        status: BookingStatus.completed,
        bookingDateTime: DateTime.now().subtract(const Duration(days: 3)),
      );

      expect(booking.canCancel, isFalse);
    });
  });
}
