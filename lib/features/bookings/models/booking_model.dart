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
  final String? bookingVehicleMake;
  final String? bookingVehicleModel;
  final bool bookingCollectorRequired;
  final String? bookingCollectorName;
  final String? bookingCollectorLicense;
  final String? appointmentResourceName;
  final String? appointmentTypeName;
  final String? opportunityName;

  // Down Payment Invoice Specific Fields
  final bool isDownPaymentInvoice;
  final double percentageAmountPaid;
  final double amountPaid;
  final String amountPaidOn;
  final double pendingAmount;
  final String carDropOffStatus;
  final List<Map<String, dynamic>> addOns;
  final int? invoiceId;
  final String? invoiceAccessUrl;
  final String? invoiceAccessToken;

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
    this.bookingVehicleMake,
    this.bookingVehicleModel,
    this.bookingCollectorRequired = false,
    this.bookingCollectorName,
    this.bookingCollectorLicense,
    this.appointmentResourceName,
    this.appointmentTypeName,
    this.opportunityName,
    this.isDownPaymentInvoice = false,
    this.percentageAmountPaid = 50.0,
    this.amountPaid = 1656.0,
    this.amountPaidOn = '31st July, 2026, 01:43 PM',
    this.pendingAmount = 1126.0,
    this.carDropOffStatus = 'Pending',
    this.addOns = const [],
    this.invoiceId,
    this.invoiceAccessUrl,
    this.invoiceAccessToken,
  });

  String get vehicleMake => bookingVehicleMake ?? (vehicleName.contains(' ') ? vehicleName.split(' ').first : vehicleName);
  String get vehicleModel => bookingVehicleModel ?? (vehicleName.contains(' ') ? vehicleName.split(' ').sublist(1).join(' ') : '');

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
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        // Convert UTC timestamp from Odoo back to Johannesburg local time (UTC+2)
        bookingTime = parsed.add(const Duration(hours: 2));
      }
    }

    DateTime? stopTime;
    final rawStop = json['stop'];
    if (rawStop != null && rawStop.toString().isNotEmpty) {
      String stopStr = rawStop.toString();
      if (stopStr.contains(' ') && !stopStr.contains('T')) {
        stopStr = stopStr.replaceAll(' ', 'T');
      }
      final parsedStop = DateTime.tryParse(stopStr);
      if (parsedStop != null) {
        // Convert UTC timestamp from Odoo back to Johannesburg local time (UTC+2)
        stopTime = parsedStop.add(const Duration(hours: 2));
      }
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
        return BookingStatus.completed;
      }
      if (odooStatus != null && odooStatus.isNotEmpty && odooStatus != 'false') {
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
        }
      }
      // Odoo calendar.event does not return a state field.
      // Classify by booking start date:
      // Past start date -> Completed Orders
      // Future start date -> Upcoming / Confirmed Bookings
      if (bookingTime.isBefore(DateTime.now())) {
        return BookingStatus.completed;
      }
      return BookingStatus.confirmed;
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
      bookingVehicleMake: make.isNotEmpty ? make : null,
      bookingVehicleModel: model.isNotEmpty ? model : null,
      bookingCollectorRequired: collectorReq,
      bookingCollectorName: collectorName,
      bookingCollectorLicense: collectorLicense,
      appointmentResourceName: apptResourceName,
      appointmentTypeName: apptTypeName,
      opportunityName: oppName,
    );
  }

  factory Booking.fromInvoiceJson(Map<String, dynamic> json) {
    final Map<String, dynamic> summary = (json['timeless_payment_summary'] is Map)
        ? Map<String, dynamic>.from(json['timeless_payment_summary'])
        : {};
    final Map<String, dynamic> snapshot = (json['timeless_content_snapshot'] is Map)
        ? Map<String, dynamic>.from(json['timeless_content_snapshot'])
        : {};

    final String vMake = (summary['vehicle_make'] ?? snapshot['vehicle_make'] ?? 'Client Vehicle').toString();
    final String vModel = (summary['vehicle_model'] ?? snapshot['vehicle_model'] ?? '').toString();
    final String vehicleName = '$vMake $vModel'.trim();
    final String vReg = (summary['vehicle_registration'] ?? snapshot['vehicle_registration'] ?? 'Hatch Back').toString();

    final List serviceLines = (summary['service_lines'] is List)
        ? (summary['service_lines'] as List)
        : (snapshot['service_lines'] is List ? snapshot['service_lines'] as List : []);

    String serviceName = 'Detailing Service';
    double origTotal = (summary['original_quotation_total'] as num?)?.toDouble() ??
        (snapshot['original_quotation_total'] as num?)?.toDouble() ??
        (json['amount_total'] as num?)?.toDouble() ??
        2800.0;

    if (serviceLines.isNotEmpty && serviceLines[0] is Map) {
      serviceName = (serviceLines[0]['name'] ?? serviceName).toString();
    }

    final double depositAmt = (summary['deposit_amount'] as num?)?.toDouble() ??
        (json['amount_total'] as num?)?.toDouble() ??
        1345.5;

    final double remainAmt = (summary['remaining_amount'] as num?)?.toDouble() ??
        (json['amount_residual'] as num?)?.toDouble() ??
        (origTotal - depositAmt);

    final String pctLabel = (summary['deposit_percentage_label'] ?? '50%').toString();
    final double pctVal = double.tryParse(pctLabel.replaceAll(RegExp(r'[^\d.]'), '')) ?? 50.0;

    final String invDateStr = (json['invoice_date'] ?? '').toString();

    final int? rawInvId = json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '');
    final String accUrl = (json['access_url'] ?? '').toString();
    final String accToken = (json['access_token'] is String) ? json['access_token'] as String : '';

    return Booking(
      id: json['id']?.toString() ?? '101',
      service: DetailService(
        id: 'inv_${json['id']}',
        name: serviceName,
        description: '',
        price: origTotal,
        durationHours: 2.0,
        imageUrl: '',
        category: 'Detailing',
        whatsIncluded: const [],
      ),
      vehicleName: vehicleName.isNotEmpty ? vehicleName : 'Volkswagen Polo TDI 2.0',
      vehicleLicensePlate: vReg,
      bookingDateTime: DateTime.tryParse(invDateStr) ?? DateTime.now(),
      status: BookingStatus.confirmed,
      currentStep: 1,
      totalPrice: origTotal,
      notes: json['name']?.toString() ?? 'Invoice',
      beforeImages: const [],
      afterImages: const [],
      technicianName: 'Master Detailer',
      technicianAvatar: '',
      isDownPaymentInvoice: json['timeless_is_down_payment_invoice'] == true || summary['is_deposit_invoice'] == true,
      percentageAmountPaid: pctVal,
      amountPaid: depositAmt,
      amountPaidOn: invDateStr.isNotEmpty ? invDateStr : '31st July, 2026, 01:43 PM',
      pendingAmount: remainAmt,
      carDropOffStatus: 'Pending',
      invoiceId: rawInvId,
      invoiceAccessUrl: accUrl.isNotEmpty ? accUrl : null,
      invoiceAccessToken: accToken.isNotEmpty ? accToken : null,
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
