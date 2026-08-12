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
  final DateTime? stopDateTime;
  final BookingStatus status;
  final int currentStep; // 0 to 4 representing visual timeline steps
  final double totalPrice;
  final String notes;
  final List<String> beforeImages;
  final List<String> afterImages;
  final String technicianName;
  final String technicianAvatar;
  final int? odooSaleOrderId; // Maps to Odoo's sale.order or calendar.event id

  // Endpoint 5 specific Odoo field keys
  final String? bookingPhone;
  final bool bookingCollectorRequired;
  final String? bookingCollectorName;
  final String? bookingCollectorLicense;
  final String? appointmentResourceName;
  final String? appointmentTypeName;
  final String? opportunityName;

  const Booking({
    required this.id,
    required this.service,
    required this.vehicleName,
    required this.vehicleLicensePlate,
    required this.bookingDateTime,
    this.stopDateTime,
    required this.status,
    required this.currentStep,
    required this.totalPrice,
    required this.notes,
    required this.beforeImages,
    required this.afterImages,
    required this.technicianName,
    required this.technicianAvatar,
    this.odooSaleOrderId,
    this.bookingPhone,
    this.bookingCollectorRequired = false,
    this.bookingCollectorName,
    this.bookingCollectorLicense,
    this.appointmentResourceName,
    this.appointmentTypeName,
    this.opportunityName,
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

  // Factory constructor for Odoo integration (supports both calendar.event and sale.order)
  factory Booking.fromOdooJson(Map<String, dynamic> json, DetailService service) {
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

    // Extraction for appointment_type_id & appointment_resource_ids
    String? apptTypeName;
    final apptTypeRaw = json['appointment_type_id'];
    if (apptTypeRaw is Map && apptTypeRaw['name'] != null) {
      apptTypeName = apptTypeRaw['name'].toString();
    } else if (apptTypeRaw is List && apptTypeRaw.length >= 2) {
      apptTypeName = apptTypeRaw[1].toString();
    }

    String? apptResourceName;
    final apptResRaw = json['appointment_resource_ids'];
    if (apptResRaw is List && apptResRaw.isNotEmpty) {
      final firstRes = apptResRaw.first;
      if (firstRes is Map && firstRes['name'] != null) {
        apptResourceName = firstRes['name'].toString();
      } else if (firstRes is List && firstRes.length >= 2) {
        apptResourceName = firstRes[1].toString();
      }
    }

    // Vehicle extraction
    String vehicleName = 'Client Vehicle';
    final make = json['booking_vehicle_make'] is String ? json['booking_vehicle_make'] as String : '';
    final model = json['booking_vehicle_model'] is String ? json['booking_vehicle_model'] as String : '';
    if (make.isNotEmpty || model.isNotEmpty) {
      vehicleName = '$make $model'.trim();
    } else if (json['vehicle_name'] is String && (json['vehicle_name'] as String).isNotEmpty) {
      vehicleName = json['vehicle_name'];
    }

    // Date extraction (calendar.event uses 'start' & 'stop')
    DateTime bookingTime = DateTime.now();
    final rawDate = json['start'] ?? json['date_order'];
    if (rawDate != null && rawDate.toString().isNotEmpty) {
      String dateStr = rawDate.toString();
      if (dateStr.contains(' ') && !dateStr.contains('T')) {
        dateStr = dateStr.replaceAll(' ', 'T');
      }
      bookingTime = DateTime.tryParse(dateStr) ?? DateTime.now();
    }

    DateTime? stopTime;
    final rawStop = json['stop'];
    if (rawStop != null && rawStop.toString().isNotEmpty) {
      String stopStr = rawStop.toString();
      if (stopStr.contains(' ') && !stopStr.contains('T')) {
        stopStr = stopStr.replaceAll(' ', 'T');
      }
      stopTime = DateTime.tryParse(stopStr);
    }

    // Collector & Phone extraction
    final phone = json['booking_phone'] is String ? json['booking_phone'] as String : null;
    final collectorReq = json['booking_collector_required'] == true;
    final collectorName = json['booking_collector_name'] is String ? json['booking_collector_name'] as String : null;
    final collectorLicense = json['booking_collector_license'] is String ? json['booking_collector_license'] as String : null;

    // Opportunity Extraction
    String? oppName;
    final oppRaw = json['opportunity_id'];
    if (oppRaw is Map && oppRaw['name'] != null) {
      oppName = oppRaw['name'].toString();
    } else if (oppRaw is List && oppRaw.length >= 2) {
      oppName = oppRaw[1].toString();
    }

    BookingStatus parseStatus(String? odooStatus, bool? active) {
      if (active == false || odooStatus == 'cancelled') {
        return BookingStatus.completed; // or cancelled state
      }
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
          if (bookingTime.isBefore(DateTime.now())) {
            return BookingStatus.completed;
          }
          return BookingStatus.confirmed;
      }
    }

    final status = parseStatus(json['state']?.toString() ?? json['appointment_status']?.toString(), json['active'] as bool?);

    return Booking(
      id: json['id']?.toString() ?? '',
      service: service,
      vehicleName: vehicleName,
      vehicleLicensePlate: json['vehicle_plate'] is String ? json['vehicle_plate'] : '',
      bookingDateTime: bookingTime,
      stopDateTime: stopTime,
      status: status,
      currentStep: parseStep(status),
      totalPrice: (json['amount_total'] as num?)?.toDouble() ?? service.price,
      notes: json['note'] is String ? json['note'] : (phone != null ? 'Phone: $phone' : ''),
      beforeImages: json['before_images'] is List 
          ? List<String>.from(json['before_images']) 
          : [],
      afterImages: json['after_images'] is List 
          ? List<String>.from(json['after_images']) 
          : [],
      technicianName: collectorName ?? (json['technician_name'] is String ? json['technician_name'] : 'Lead Detailer'),
      technicianAvatar: json['technician_avatar'] is String ? json['technician_avatar'] : '',
      odooSaleOrderId: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      bookingPhone: phone,
      bookingCollectorRequired: collectorReq,
      bookingCollectorName: collectorName,
      bookingCollectorLicense: collectorLicense,
      appointmentResourceName: apptResourceName,
      appointmentTypeName: apptTypeName,
      opportunityName: oppName,
    );
  }

  Booking copyWith({
    String? id,
    DetailService? service,
    String? vehicleName,
    String? vehicleLicensePlate,
    DateTime? bookingDateTime,
    DateTime? stopDateTime,
    BookingStatus? status,
    int? currentStep,
    double? totalPrice,
    String? notes,
    List<String>? beforeImages,
    List<String>? afterImages,
    String? technicianName,
    String? technicianAvatar,
    int? odooSaleOrderId,
    String? bookingPhone,
    bool? bookingCollectorRequired,
    String? bookingCollectorName,
    String? bookingCollectorLicense,
    String? appointmentResourceName,
    String? appointmentTypeName,
    String? opportunityName,
  }) {
    return Booking(
      id: id ?? this.id,
      service: service ?? this.service,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleLicensePlate: vehicleLicensePlate ?? this.vehicleLicensePlate,
      bookingDateTime: bookingDateTime ?? this.bookingDateTime,
      stopDateTime: stopDateTime ?? this.stopDateTime,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      beforeImages: beforeImages ?? this.beforeImages,
      afterImages: afterImages ?? this.afterImages,
      technicianName: technicianName ?? this.technicianName,
      technicianAvatar: technicianAvatar ?? this.technicianAvatar,
      odooSaleOrderId: odooSaleOrderId ?? this.odooSaleOrderId,
      bookingPhone: bookingPhone ?? this.bookingPhone,
      bookingCollectorRequired: bookingCollectorRequired ?? this.bookingCollectorRequired,
      bookingCollectorName: bookingCollectorName ?? this.bookingCollectorName,
      bookingCollectorLicense: bookingCollectorLicense ?? this.bookingCollectorLicense,
      appointmentResourceName: appointmentResourceName ?? this.appointmentResourceName,
      appointmentTypeName: appointmentTypeName ?? this.appointmentTypeName,
      opportunityName: opportunityName ?? this.opportunityName,
    );
  }
}
