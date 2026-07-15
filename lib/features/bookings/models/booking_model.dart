import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';

enum BookingStatus {
  confirmed,    // Appointment scheduled
  received,     // Car dropped off & checked in
  inProgress,   // In the detailing bay (washing, polishing, coating)
  ready,        // Detailing completed, ready for client pickup
  completed,    // Car picked up, invoice paid
}

class Booking {
  final String id;
  final DetailService service;
  final String vehicleName;
  final String vehicleLicensePlate;
  final DateTime bookingDateTime;
  final BookingStatus status;
  final int currentStep; // 0 to 4 representing visual timeline steps
  final double totalPrice;
  final String notes;
  final List<String> beforeImages;
  final List<String> afterImages;
  final String technicianName;
  final String technicianAvatar;
  final int? odooSaleOrderId; // Maps to Odoo's sale.order (or custom detailing.booking) id

  const Booking({
    required this.id,
    required this.service,
    required this.vehicleName,
    required this.vehicleLicensePlate,
    required this.bookingDateTime,
    required this.status,
    required this.currentStep,
    required this.totalPrice,
    required this.notes,
    required this.beforeImages,
    required this.afterImages,
    required this.technicianName,
    required this.technicianAvatar,
    this.odooSaleOrderId,
  });

  // Returns human readable status title
  String get statusTitle {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.received:
        return 'Vehicle Received';
      case BookingStatus.inProgress:
        return 'Detailing In Progress';
      case BookingStatus.ready:
        return 'Ready for Pickup';
      case BookingStatus.completed:
        return 'Completed';
    }
  }

  // Returns progress percentage for progress bars (0.0 to 1.0)
  double get progressPercentage {
    switch (status) {
      case BookingStatus.confirmed:
        return 0.2;
      case BookingStatus.received:
        return 0.4;
      case BookingStatus.inProgress:
        return 0.7;
      case BookingStatus.ready:
        return 0.9;
      case BookingStatus.completed:
        return 1.0;
    }
  }

  // Factory constructor for Odoo integration
  factory Booking.fromOdooJson(Map<String, dynamic> json, DetailService service) {
    BookingStatus parseStatus(String? odooStatus) {
      switch (odooStatus) {
        case 'draft':
        case 'sent':
        case 'sale':
          return BookingStatus.confirmed;
        case 'received':
        case 'checked_in':
          return BookingStatus.received;
        case 'in_progress':
        case 'detailing':
          return BookingStatus.inProgress;
        case 'ready':
        case 'done':
          return BookingStatus.ready;
        case 'completed':
        case 'done_picked_up':
          return BookingStatus.completed;
        default:
          return BookingStatus.confirmed;
      }
    }

    int parseStep(BookingStatus bookingStatus) {
      switch (bookingStatus) {
        case BookingStatus.confirmed:
          return 0;
        case BookingStatus.received:
          return 1;
        case BookingStatus.inProgress:
          return 2;
        case BookingStatus.ready:
          return 3;
        case BookingStatus.completed:
          return 4;
      }
    }

    return Booking(
      id: json['id']?.toString() ?? '',
      service: service,
      vehicleName: json['vehicle_name'] ?? 'Client Vehicle',
      vehicleLicensePlate: json['vehicle_plate'] ?? '',
      bookingDateTime: json['date_order'] != null 
          ? DateTime.tryParse(json['date_order'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: parseStatus(json['state']?.toString()),
      currentStep: parseStep(parseStatus(json['state']?.toString())),
      totalPrice: (json['amount_total'] as num?)?.toDouble() ?? service.price,
      notes: json['note'] ?? '',
      beforeImages: json['before_images'] is List 
          ? List<String>.from(json['before_images']) 
          : [],
      afterImages: json['after_images'] is List 
          ? List<String>.from(json['after_images']) 
          : [],
      technicianName: json['technician_name'] ?? 'Lead Detailer',
      technicianAvatar: json['technician_avatar'] ?? '',
      odooSaleOrderId: json['id'] is int ? json['id'] as int : null,
    );
  }

  Booking copyWith({
    String? id,
    DetailService? service,
    String? vehicleName,
    String? vehicleLicensePlate,
    DateTime? bookingDateTime,
    BookingStatus? status,
    int? currentStep,
    double? totalPrice,
    String? notes,
    List<String>? beforeImages,
    List<String>? afterImages,
    String? technicianName,
    String? technicianAvatar,
    int? odooSaleOrderId,
  }) {
    return Booking(
      id: id ?? this.id,
      service: service ?? this.service,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleLicensePlate: vehicleLicensePlate ?? this.vehicleLicensePlate,
      bookingDateTime: bookingDateTime ?? this.bookingDateTime,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      beforeImages: beforeImages ?? this.beforeImages,
      afterImages: afterImages ?? this.afterImages,
      technicianName: technicianName ?? this.technicianName,
      technicianAvatar: technicianAvatar ?? this.technicianAvatar,
      odooSaleOrderId: odooSaleOrderId ?? this.odooSaleOrderId,
    );
  }
}
