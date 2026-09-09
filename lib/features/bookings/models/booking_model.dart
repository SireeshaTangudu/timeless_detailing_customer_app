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
  final List<Map<String, dynamic>> timelessProjects;

  // Down Payment Invoice Specific Fields
  final bool isDownPaymentInvoice;
  final double percentageAmountPaid;
  final double amountPaid;
  final String amountPaidOn;
  final double pendingAmount;
  final double thisInvoiceAmount;
  final String carDropOffStatus;
  final List<Map<String, dynamic>> addOns;
  final int? invoiceId;
  final String? invoiceAccessUrl;
  final String? invoiceAccessToken;
  final String? invoicePaymentState;
  final String? warrantyLabel;
  final DateTime? invoiceDueDate;

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
    this.timelessProjects = const [],
    this.isDownPaymentInvoice = false,
    this.percentageAmountPaid = 0.0,
    this.amountPaid = 0.0,
    this.thisInvoiceAmount = 0.0,
    this.amountPaidOn = '',
    this.pendingAmount = 0.0,
    this.carDropOffStatus = '',
    this.addOns = const [],
    this.invoiceId,
    this.invoiceAccessUrl,
    this.invoiceAccessToken,
    this.invoicePaymentState,
    this.warrantyLabel,
    this.invoiceDueDate,
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

  // Indicates whether the booking can still be cancelled by the user.
  // Cancellation is only allowed for confirmed appointments whose start time is in the future.
  bool get canCancel {
    return status == BookingStatus.confirmed && bookingDateTime.isAfter(DateTime.now());
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

    // Extraction for product_id (Map or List object from Odoo API)
    String? prodDisplayName;
    String? prodName;
    String? prodVariantName;
    int? prodId;

    final prodRaw = json['product_id'];
    if (prodRaw is Map) {
      if (prodRaw['id'] is int) prodId = prodRaw['id'] as int;
      if (prodRaw['display_name'] != null) prodDisplayName = prodRaw['display_name'].toString();
      if (prodRaw['name'] != null) prodName = prodRaw['name'].toString();

      final tmplRaw = prodRaw['product_tmpl_id'];
      if (tmplRaw is Map && tmplRaw['name'] != null && prodName == null) {
        prodName = tmplRaw['name'].toString();
      }

      final variantsRaw = prodRaw['product_template_variant_value_ids'];
      if (variantsRaw is List && variantsRaw.isNotEmpty) {
        final vList = <String>[];
        for (final v in variantsRaw) {
          if (v is Map && v['name'] != null) {
            vList.add(v['name'].toString());
          } else if (v is List && v.length >= 2) {
            vList.add(v[1].toString());
          }
        }
        if (vList.isNotEmpty) {
          prodVariantName = vList.join(', ');
        }
      }
    } else if (prodRaw is List && prodRaw.length >= 2) {
      if (prodRaw[0] is int) prodId = prodRaw[0] as int;
      prodDisplayName = prodRaw[1].toString();
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

    // Dynamic service construction from API fields without hardcoded fallbacks
    final String dynamicServiceName = prodDisplayName ??
        prodName ??
        apptResourceName ??
        apptTypeName ??
        (json['name'] is String && (json['name'] as String).isNotEmpty ? json['name'] as String : service.name);

    final DetailService finalService = DetailService(
      id: prodId?.toString() ?? (service.id.isNotEmpty ? service.id : (json['id']?.toString() ?? '')),
      name: dynamicServiceName,
      description: prodVariantName != null ? 'Variant: $prodVariantName' : service.description,
      price: (json['amount_total'] as num?)?.toDouble() ?? service.price,
      durationHours: (json['duration'] as num?)?.toDouble() ?? service.durationHours,
      imageUrl: service.imageUrl,
      category: apptTypeName ?? service.category,
      whatsIncluded: service.whatsIncluded,
    );

    // Vehicle extraction
    String vehicleName = '';
    String? vehicleReg = json['vehicle_registration']?.toString() ?? (json['vehicle_plate'] is String ? json['vehicle_plate'] as String : null);
    String make = json['booking_vehicle_make']?.toString() ?? json['vehicle_make']?.toString() ?? '';
    String model = json['booking_vehicle_model']?.toString() ?? json['vehicle_model']?.toString() ?? '';

    if (json['vehicle_id'] is Map) {
      final vMap = json['vehicle_id'] as Map;
      final vMake = vMap['make']?.toString() ?? '';
      final vModel = vMap['model']?.toString() ?? '';
      if (vMake.isNotEmpty) make = vMake;
      if (vModel.isNotEmpty) model = vModel;
      vehicleName = '$vMake $vModel'.trim();
      if (vehicleReg == null || vehicleReg.isEmpty) {
        vehicleReg = vMap['registration']?.toString();
      }
    }

    if (vehicleName.isEmpty) {
      if (make.isNotEmpty || model.isNotEmpty) {
        vehicleName = '$make $model'.trim();
      } else if (json['vehicle_name'] is String && (json['vehicle_name'] as String).isNotEmpty) {
        vehicleName = json['vehicle_name'] as String;
      }
    }

    if (vehicleReg == null || vehicleReg.isEmpty) {
      vehicleReg = json['vehicle_registration']?.toString() ?? (json['vehicle_plate'] is String ? json['vehicle_plate'] as String : '');
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

    // Extract timeless_project_ids
    List<Map<String, dynamic>> timelessProjectsList = [];
    final rawProjects = json['timeless_project_ids'];
    if (rawProjects is List) {
      for (final p in rawProjects) {
        if (p is Map) {
          timelessProjectsList.add(Map<String, dynamic>.from(p));
        }
      }
    } else if (rawProjects is Map) {
      timelessProjectsList.add(Map<String, dynamic>.from(rawProjects));
    }

    BookingStatus parseStatus(String? odooStatus, bool? active) {
      // Rule 1: If active = false or cancelled -> Cancelled / Closed
      if (active == false || odooStatus == 'cancelled') {
        return BookingStatus.completed;
      }

      if (odooStatus == 'done_picked_up') {
        return BookingStatus.completed;
      }

      final now = DateTime.now();

      final bool hasSalesOrder = json['opportunity_id'] != null && json['opportunity_id'] != false;
      final bool hasProjects = timelessProjectsList.isNotEmpty;
      final bool hasSalesOrderOrProject = hasSalesOrder || hasProjects;

      // Rule 2: If there is no Sales Order / no Project yet:
      // start > now -> Upcoming (confirmed)
      // start <= now -> Past / Pending (completed)
      if (!hasSalesOrderOrProject) {
        if (bookingTime.isAfter(now)) {
          return BookingStatus.confirmed;
        } else {
          return BookingStatus.completed;
        }
      }

      // Rule 3: If a Sales Order exists and one or more relevant Projects are linked:
      // Check if ALL relevant Projects are completed / Done (fold == true or stage name done/completed):
      final bool allProjectsDone = hasProjects &&
          timelessProjectsList.every((proj) {
            final stage = proj['stage_id'];
            if (stage is Map) {
              final isFolded = stage['fold'] == true;
              final stageName = (stage['name'] ?? '').toString().toLowerCase();
              return isFolded ||
                  stageName.contains('done') ||
                  stageName.contains('complet') ||
                  stageName.contains('finish');
            }
            return false;
          });

      // Rule 4: If all relevant Projects are completed / Done -> Completed
      if (hasProjects && allProjectsDone) {
        return BookingStatus.completed;
      }

      // Rule 5: If any relevant Project is not completed:
      // start > now -> Upcoming
      // start <= now -> In Progress
      if (bookingTime.isAfter(now)) {
        return BookingStatus.confirmed;
      } else {
        return BookingStatus.inProgress;
      }
    }

    final status = parseStatus(json['state']?.toString() ?? json['appointment_status']?.toString(), json['active'] as bool?);

    return Booking(
      id: json['id']?.toString() ?? '',
      service: finalService,
      vehicleName: vehicleName,
      vehicleLicensePlate: json['vehicle_plate'] is String ? json['vehicle_plate'] : '',
      bookingDateTime: bookingTime,
      stopDateTime: stopTime,
      status: status,
      currentStep: parseStep(status),
      totalPrice: (json['amount_total'] as num?)?.toDouble() ?? finalService.price,
      notes: json['note'] is String ? json['note'] : (phone != null ? 'Phone: $phone' : ''),
      beforeImages: json['before_images'] is List 
          ? List<String>.from(json['before_images']) 
          : [],
      afterImages: json['after_images'] is List 
          ? List<String>.from(json['after_images']) 
          : [],
      technicianName: collectorName ?? (json['technician_name'] is String ? json['technician_name'] as String : ''),
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
      timelessProjects: timelessProjectsList,
    );
  }

  factory Booking.fromInvoiceJson(Map<String, dynamic> json) {
    final Map<String, dynamic> summary = (json['timeless_payment_summary'] is Map)
        ? Map<String, dynamic>.from(json['timeless_payment_summary'])
        : {};
    final Map<String, dynamic> snapshot = (json['timeless_content_snapshot'] is Map)
        ? Map<String, dynamic>.from(json['timeless_content_snapshot'])
        : {};

    final String vMake = (summary['vehicle_make'] ?? snapshot['vehicle_make'] ?? '').toString();
    final String vModel = (summary['vehicle_model'] ?? snapshot['vehicle_model'] ?? '').toString();
    final String rawVName = '$vMake $vModel'.trim();
    final String vehicleName = rawVName.isNotEmpty
        ? rawVName
        : (json['name'] != null ? json['name'].toString() : '');
    final String vReg = (summary['vehicle_registration'] ?? snapshot['vehicle_registration'] ?? '').toString();

    final List serviceLines = (summary['service_lines'] is List && (summary['service_lines'] as List).isNotEmpty)
        ? (summary['service_lines'] as List)
        : ((snapshot['service_lines'] is List && (snapshot['service_lines'] as List).isNotEmpty)
            ? (snapshot['service_lines'] as List)
            : (json['invoice_line_ids'] is List ? (json['invoice_line_ids'] as List) : []));

    String serviceName = '';
    String? warrantyLabel;

    double origTotal = (summary['current_order_total'] as num?)?.toDouble() ??
        (snapshot['current_order_total'] as num?)?.toDouble() ??
        (summary['original_quotation_total'] as num?)?.toDouble() ??
        (snapshot['original_quotation_total'] as num?)?.toDouble() ??
        (json['amount_total'] as num?)?.toDouble() ??
        0.0;

    final List<Map<String, dynamic>> parsedAddOns = [];

    if (serviceLines.isNotEmpty) {
      if (serviceLines[0] is Map) {
        serviceName = (serviceLines[0]['name'] ?? serviceName).toString();
      }
      for (final s in serviceLines) {
        if (s is Map) {
          final rawWarranty = s['warranty_label']?.toString();
          if (warrantyLabel == null &&
              rawWarranty != null &&
              rawWarranty.isNotEmpty &&
              rawWarranty != 'null' &&
              rawWarranty != 'false') {
            warrantyLabel = rawWarranty;
          }
        }
      }
      if (serviceLines.length > 1) {
        for (int i = 1; i < serviceLines.length; i++) {
          if (serviceLines[i] is Map) {
            final item = Map<String, dynamic>.from(serviceLines[i] as Map);
            parsedAddOns.add({
              'name': (item['name'] ?? '').toString(),
              'price': (item['price_total'] as num?)?.toDouble() ?? 0.0,
              'warranty_label': item['warranty_label'],
            });
          }
        }
      }
    }

    final bool isDepositInvoice = json['timeless_is_down_payment_invoice'] == true || summary['is_deposit_invoice'] == true;

    final double depositAmt = (summary['deposit_amount'] as num?)?.toDouble() ??
        (isDepositInvoice ? (json['amount_total'] as num?)?.toDouble() ?? 0.0 : 0.0);

    final double totalPaidSoFar = (summary['amount_paid'] as num?)?.toDouble() ?? 0.0;

    final double thisInvAmt = (summary['this_invoice_amount'] as num?)?.toDouble() ??
        (json['amount_total'] as num?)?.toDouble() ??
        0.0;

    final double thisInvResidual = (json['amount_residual'] as num?)?.toDouble() ?? thisInvAmt;

    double remainAmt;
    if (isDepositInvoice) {
      remainAmt = (summary['remaining_amount'] as num?)?.toDouble() ??
          (origTotal > 0 ? (origTotal - depositAmt) : 0.0);
    } else {
      final double outstanding = (summary['outstanding_balance'] as num?)?.toDouble() ?? thisInvResidual;
      remainAmt = (outstanding - thisInvResidual).clamp(0.0, double.infinity);
    }

    final String pctLabel = (summary['deposit_percentage_label'] ?? '').toString();
    final double pctVal = double.tryParse(pctLabel.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

    final String invDateStr = (json['invoice_date'] ?? '').toString();
    final String dueDateStr = (json['invoice_date_due'] ?? '').toString();
    final String payState = (json['payment_state'] ?? '').toString();

    final int? rawInvId = json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '');
    final String accUrl = (json['access_url'] ?? '').toString();
    final String accToken = (json['access_token'] is String) ? json['access_token'] as String : '';

    return Booking(
      id: json['id']?.toString() ?? '',
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
      vehicleName: vehicleName,
      vehicleLicensePlate: vReg,
      bookingDateTime: DateTime.tryParse(invDateStr) ?? DateTime.now(),
      status: BookingStatus.confirmed,
      currentStep: 1,
      totalPrice: origTotal,
      notes: json['name']?.toString() ?? 'Invoice',
      beforeImages: const [],
      afterImages: const [],
      technicianName: '',
      technicianAvatar: '',
      bookingVehicleMake: vMake.isNotEmpty ? vMake : null,
      bookingVehicleModel: vModel.isNotEmpty ? vModel : null,
      isDownPaymentInvoice: isDepositInvoice,
      percentageAmountPaid: pctVal,
      amountPaid: isDepositInvoice ? depositAmt : (totalPaidSoFar > 0 ? totalPaidSoFar : depositAmt),
      thisInvoiceAmount: thisInvAmt,
      amountPaidOn: invDateStr.isNotEmpty ? invDateStr : '',
      pendingAmount: remainAmt,
      carDropOffStatus: '',
      addOns: parsedAddOns,
      invoiceId: rawInvId,
      invoiceAccessUrl: accUrl.isNotEmpty ? accUrl : null,
      invoiceAccessToken: accToken.isNotEmpty ? accToken : null,
      invoicePaymentState: payState,
      warrantyLabel: warrantyLabel,
      invoiceDueDate: DateTime.tryParse(dueDateStr),
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
