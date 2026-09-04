import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';

class EstimationStepModel {
  final int stepNumber;
  final String title;
  final String? description;
  final bool isCompleted;

  const EstimationStepModel({
    required this.stepNumber,
    required this.title,
    this.description,
    this.isCompleted = false,
  });

  factory EstimationStepModel.fromJson(Map<String, dynamic> json) {
    return EstimationStepModel(
      stepNumber: json['step_number'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step_number': stepNumber,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
    };
  }
}

class EstimationLineItemModel {
  final int id;
  final int? productId;
  final String productName;
  final String description;
  final double quantity;
  final double priceUnit;
  final double discount;
  final double priceSubtotal;
  final double priceTotal;

  const EstimationLineItemModel({
    required this.id,
    this.productId,
    required this.productName,
    required this.description,
    required this.quantity,
    required this.priceUnit,
    required this.discount,
    required this.priceSubtotal,
    required this.priceTotal,
  });

  factory EstimationLineItemModel.fromJson(Map<String, dynamic> json) {
    int? pId;
    String pName = '';
    if (json['product_id'] is Map) {
      pId = (json['product_id'] as Map)['id'] as int?;
      pName = (json['product_id'] as Map)['display_name']?.toString() ?? '';
    }
    final nameStr = json['name']?.toString() ?? pName;

    return EstimationLineItemModel(
      id: json['id'] is int ? json['id'] as int : 0,
      productId: pId,
      productName: pName.isNotEmpty ? pName : (nameStr.isNotEmpty ? nameStr : 'Detailing Service'),
      description: nameStr,
      quantity: (json['product_uom_qty'] as num?)?.toDouble() ?? 1.0,
      priceUnit: (json['price_unit'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      priceSubtotal: (json['price_subtotal'] as num?)?.toDouble() ?? 0.0,
      priceTotal: (json['price_total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'description': description,
      'quantity': quantity,
      'price_unit': priceUnit,
      'discount': discount,
      'price_subtotal': priceSubtotal,
      'price_total': priceTotal,
    };
  }
}

class EstimationModel {
  final String id;
  final int? odooSaleOrderId;
  final String serviceName;
  final String serviceDescription;
  final double estimatedAmount;
  final double? amountUntaxed;
  final double? amountTax;
  final String currencySymbol;
  final String vehicleName;
  final String vehicleType;
  final String? vehicleRegistration;
  final String? vehicleVin;
  final String serviceDate;
  final String serviceTime;
  final String? validityDate;
  final String disclaimerText;
  final String state; // 'draft', 'sent', 'sale', 'cancel'
  final String? notificationType; // 'appointment_booked', 'quotation_sent', etc.
  final List<EstimationLineItemModel> lineItems;
  final List<EstimationStepModel> nextSteps;

  const EstimationModel({
    required this.id,
    this.odooSaleOrderId,
    required this.serviceName,
    required this.serviceDescription,
    required this.estimatedAmount,
    this.amountUntaxed,
    this.amountTax,
    required this.currencySymbol,
    required this.vehicleName,
    required this.vehicleType,
    this.vehicleRegistration,
    this.vehicleVin,
    required this.serviceDate,
    required this.serviceTime,
    this.validityDate,
    required this.disclaimerText,
    this.state = 'sent',
    this.notificationType,
    this.lineItems = const [],
    required this.nextSteps,
  });

  bool get isQuotationSent =>
      state == 'sent' || state == 'sale' || notificationType == 'quotation_sent';

  /// Static default estimation model matching Figma design prototype
  factory EstimationModel.defaultStatic() {
    return const EstimationModel(
      id: 'EST-28001',
      serviceName: 'Interior Detailing',
      serviceDescription: 'Estimated cost for your interior detailing service',
      estimatedAmount: 2800.0,
      amountUntaxed: 2434.78,
      amountTax: 365.22,
      currencySymbol: 'R',
      vehicleName: 'Volkswagen Polo TDI 2.0',
      vehicleType: 'Hatch Back',
      serviceDate: '12th August',
      serviceTime: '12:00 PM',
      disclaimerText:
          'The above mentioned amount is the base price. We will share the final pricing after completing our inspection on 12th August at 12:00 PM.',
      state: 'sent',
      notificationType: 'quotation_sent',
      lineItems: [],
      nextSteps: [
        EstimationStepModel(
          stepNumber: 1,
          title: 'Book your slot with us',
          isCompleted: true,
        ),
        EstimationStepModel(
          stepNumber: 2,
          title: 'Inspection of your car on the booked slot',
        ),
        EstimationStepModel(
          stepNumber: 3,
          title: 'New quote with the updated amount post inspection',
        ),
        EstimationStepModel(
          stepNumber: 4,
          title: 'Accept the quote',
        ),
        EstimationStepModel(
          stepNumber: 5,
          title: 'Get your car serviced!',
        ),
      ],
    );
  }

  /// Construct estimation from existing booking model
  factory EstimationModel.fromBooking(
    Booking booking, {
    String? vehicleType,
    bool isDraft = true,
  }) {
    final dateStr =
        '${booking.bookingDateTime.day} ${_monthName(booking.bookingDateTime.month)}';
    final hour = booking.bookingDateTime.hour % 12 == 0
        ? 12
        : booking.bookingDateTime.hour % 12;
    final amPm = booking.bookingDateTime.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = booking.bookingDateTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minuteStr $amPm';

    return EstimationModel(
      id: 'EST-${booking.id.isNotEmpty ? booking.id : "001"}',
      serviceName: booking.service.name,
      serviceDescription:
          'Estimated cost for your ${booking.service.name.toLowerCase()} service',
      estimatedAmount: booking.totalPrice > 0 ? booking.totalPrice : 2800.0,
      currencySymbol: 'R',
      vehicleName: booking.vehicleName.isNotEmpty
          ? booking.vehicleName
          : 'Volkswagen Polo TDI 2.0',
      vehicleType: vehicleType ?? 'Hatch Back',
      serviceDate: dateStr,
      serviceTime: timeStr,
      disclaimerText:
          'The above mentioned amount is the base price. We will share the final pricing after completing our inspection on $dateStr at $timeStr.',
      state: isDraft ? 'draft' : 'sent',
      notificationType: isDraft ? 'appointment_booked' : 'quotation_sent',
      lineItems: const [],
      nextSteps: const [
        EstimationStepModel(
          stepNumber: 1,
          title: 'Book your slot with us',
          isCompleted: true,
        ),
        EstimationStepModel(
          stepNumber: 2,
          title: 'Inspection of your car on the booked slot',
        ),
        EstimationStepModel(
          stepNumber: 3,
          title: 'New quote with the updated amount post inspection',
        ),
        EstimationStepModel(
          stepNumber: 4,
          title: 'Accept the quote',
        ),
        EstimationStepModel(
          stepNumber: 5,
          title: 'Get your car serviced!',
        ),
      ],
    );
  }

  /// Factory for parsing sale.order / quotation from Odoo
  factory EstimationModel.fromOdooJson(Map<String, dynamic> json) {
    final rawAmount = json['amount_total'] ?? json['estimated_amount'];
    final amountVal = (rawAmount is num) ? rawAmount.toDouble() : 0.0;

    final untaxedVal = json['amount_untaxed'] is num
        ? (json['amount_untaxed'] as num).toDouble()
        : null;
    final taxVal = json['amount_tax'] is num
        ? (json['amount_tax'] as num).toDouble()
        : null;

    final orderState = json['state']?.toString() ?? 'sent';
    final nameStr = json['name']?.toString() ?? (json['id'] != null ? 'SO-00${json['id']}' : 'SO-001');
    final int? saleOrderId = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '');
    final notifType = json['notification_type']?.toString();

    // Parse order_line items dynamically
    List<EstimationLineItemModel> lines = [];
    final rawOrderLines = json['order_line'] ?? json['order_lines_detail'];
    if (rawOrderLines is List) {
      for (final item in rawOrderLines) {
        if (item is Map<String, dynamic>) {
          lines.add(EstimationLineItemModel.fromJson(item));
        } else if (item is Map) {
          lines.add(EstimationLineItemModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    String serviceNameStr = '';
    if (lines.isNotEmpty) {
      serviceNameStr = lines.map((l) => l.productName).where((n) => n.isNotEmpty).join(', ');
      if (serviceNameStr.isEmpty) serviceNameStr = lines.first.description;
    } else if (json['service_name'] != null) {
      serviceNameStr = json['service_name'].toString();
    }
    if (serviceNameStr.isEmpty) {
      serviceNameStr = 'Vehicle Detailing Service';
    }

    String vehicleNameStr = '';
    String? vehicleReg;
    String? vehicleVin;

    if (json['vehicle_id'] is Map) {
      final vMap = json['vehicle_id'] as Map;
      final make = vMap['make']?.toString() ?? '';
      final model = vMap['model']?.toString() ?? '';
      vehicleNameStr = '$make $model'.trim();
      vehicleReg = vMap['registration']?.toString();
      vehicleVin = vMap['vin']?.toString();
    }

    if (vehicleNameStr.isEmpty) {
      final make = json['vehicle_make']?.toString() ?? '';
      final model = json['vehicle_model']?.toString() ?? '';
      vehicleNameStr = '$make $model'.trim();
    }

    if (vehicleReg == null || vehicleReg.isEmpty) {
      vehicleReg = json['vehicle_registration']?.toString();
    }

    if (vehicleNameStr.isEmpty) {
      vehicleNameStr = 'Client Vehicle';
    }

    String dateStr = 'Today';
    String timeStr = '12:00 PM';
    if (json['date_order'] != null && json['date_order'].toString().isNotEmpty) {
      final dt = DateTime.tryParse(json['date_order'].toString().replaceAll(' ', 'T'));
      if (dt != null) {
        final localDt = dt.add(const Duration(hours: 2));
        dateStr = '${localDt.day} ${_monthName(localDt.month)} ${localDt.year}';
        final hour = localDt.hour % 12 == 0 ? 12 : localDt.hour % 12;
        final amPm = localDt.hour >= 12 ? 'PM' : 'AM';
        final minStr = localDt.minute.toString().padLeft(2, '0');
        timeStr = '$hour:$minStr $amPm';
      }
    }

    String? validityStr;
    if (json['validity_date'] != null && json['validity_date'].toString().isNotEmpty) {
      final dtVal = DateTime.tryParse(json['validity_date'].toString());
      if (dtVal != null) {
        validityStr = '${dtVal.day} ${_monthName(dtVal.month)} ${dtVal.year}';
      } else {
        validityStr = json['validity_date'].toString();
      }
    }

    return EstimationModel(
      id: nameStr,
      odooSaleOrderId: saleOrderId,
      serviceName: serviceNameStr,
      serviceDescription: 'Quotation sent by Timeless Detailing',
      estimatedAmount: amountVal,
      amountUntaxed: untaxedVal,
      amountTax: taxVal,
      currencySymbol: 'R',
      vehicleName: vehicleNameStr,
      vehicleType: json['vehicle_type']?.toString() ??
          (vehicleReg != null && vehicleReg.isNotEmpty ? 'Reg: $vehicleReg' : 'Vehicle'),
      vehicleRegistration: vehicleReg,
      vehicleVin: vehicleVin,
      serviceDate: dateStr,
      serviceTime: timeStr,
      validityDate: validityStr,
      disclaimerText:
          'Please review the breakdown above and click Accept & Sign below to confirm your estimate.',
      state: orderState,
      notificationType: notifType ?? (orderState == 'draft' ? 'appointment_booked' : 'quotation_sent'),
      lineItems: lines,
      nextSteps: [
        const EstimationStepModel(
          stepNumber: 1,
          title: 'Book your slot with us',
          isCompleted: true,
        ),
        const EstimationStepModel(
          stepNumber: 2,
          title: 'Inspection of your car on the booked slot',
          isCompleted: true,
        ),
        EstimationStepModel(
          stepNumber: 3,
          title: 'New quote with the updated amount post inspection',
          isCompleted: orderState == 'sent' || orderState == 'sale',
        ),
        EstimationStepModel(
          stepNumber: 4,
          title: 'Accept the quote',
          isCompleted: orderState == 'sale',
        ),
        const EstimationStepModel(
          stepNumber: 5,
          title: 'Get your car serviced!',
        ),
      ],
    );
  }

  /// Factory specifically constructed from Odoo / Push notification JSON payload
  factory EstimationModel.fromNotificationJson(Map<String, dynamic> json) {
    final notifType = (json['notification_type'] ?? json['type'] ?? '').toString().toLowerCase();
    final resModel = (json['res_model'] ?? json['model'] ?? '').toString().toLowerCase();
    final rawSaleOrderId = json['sale_order_id'];

    int? saleOrderId;
    if (rawSaleOrderId is List && rawSaleOrderId.isNotEmpty && rawSaleOrderId.first is int) {
      saleOrderId = rawSaleOrderId.first as int;
    } else if (rawSaleOrderId is int) {
      saleOrderId = rawSaleOrderId;
    } else if (rawSaleOrderId is String) {
      saleOrderId = int.tryParse(rawSaleOrderId);
    }

    final bool isQuotationSent = notifType == 'quotation_sent' ||
        resModel == 'sale.order' ||
        (saleOrderId != null && saleOrderId > 0);

    final String notifMsg = json['message']?.toString() ?? json['body']?.toString() ?? '';

    String serviceNameStr = 'Vehicle Detailing Service';
    String serviceDateStr = json['service_date']?.toString() ?? 'Scheduled Slot';
    String serviceTimeStr = json['service_time']?.toString() ?? '12:00 PM';

    if (notifMsg.contains('for ') && notifMsg.contains(' is confirmed for ')) {
      final parts = notifMsg.split(' is confirmed for ');
      if (parts.length == 2) {
        final servicePart = parts[0].replaceAll('Your appointment for ', '').trim();
        if (servicePart.isNotEmpty) serviceNameStr = servicePart;

        final dateTimePart = parts[1].replaceAll('.', '').trim();
        final dtParts = dateTimePart.split(', ');
        if (dtParts.length == 2) {
          serviceDateStr = dtParts[0].trim();
          serviceTimeStr = dtParts[1].trim();
        } else if (dtParts.isNotEmpty) {
          serviceDateStr = dtParts[0].trim();
        }
      }
    } else if (notifMsg.contains('for ')) {
      final parts = notifMsg.split('for ');
      if (parts.length > 1) {
        final sub = parts[1].split(' is confirmed')[0].split(' on ')[0].trim();
        if (sub.isNotEmpty) serviceNameStr = sub;
      }
    }

    final String resIdStr = (json['res_id'] ?? json['id'] ?? '100').toString();

    final disclaimer = isQuotationSent
        ? 'Please review the breakdown above and click Accept & Sign below to confirm your estimate.'
        : 'The above mentioned amount is the base price. We will share the final pricing after completing our inspection on $serviceDateStr at $serviceTimeStr.';

    List<EstimationLineItemModel> lines = [];
    final rawOrderLines = json['order_line'] ?? json['order_lines_detail'];
    if (rawOrderLines is List) {
      for (final item in rawOrderLines) {
        if (item is Map<String, dynamic>) {
          lines.add(EstimationLineItemModel.fromJson(item));
        } else if (item is Map) {
          lines.add(EstimationLineItemModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return EstimationModel(
      id: saleOrderId != null ? 'SO-00$saleOrderId' : 'EST-$resIdStr',
      odooSaleOrderId: saleOrderId,
      serviceName: serviceNameStr,
      serviceDescription: isQuotationSent
          ? 'Final quotation sent by Timeless Detailing Technician'
          : 'Estimated cost for your ${serviceNameStr.toLowerCase()} service',
      estimatedAmount: (json['amount_total'] ?? json['estimated_amount'] as num?)?.toDouble() ?? 2800.0,
      amountUntaxed: (json['amount_untaxed'] as num?)?.toDouble(),
      amountTax: (json['amount_tax'] as num?)?.toDouble(),
      currencySymbol: 'R',
      vehicleName: json['vehicle_name']?.toString() ?? 'Client Vehicle',
      vehicleType: json['vehicle_type']?.toString() ?? 'Vehicle',
      serviceDate: serviceDateStr,
      serviceTime: serviceTimeStr,
      disclaimerText: disclaimer,
      state: isQuotationSent ? 'sent' : 'draft',
      notificationType: isQuotationSent ? 'quotation_sent' : 'appointment_booked',
      lineItems: lines,
      nextSteps: [
        const EstimationStepModel(
          stepNumber: 1,
          title: 'Book your slot with us',
          isCompleted: true,
        ),
        EstimationStepModel(
          stepNumber: 2,
          title: 'Inspection of your car on the booked slot',
          isCompleted: isQuotationSent,
        ),
        EstimationStepModel(
          stepNumber: 3,
          title: 'New quote with the updated amount post inspection',
          isCompleted: isQuotationSent,
        ),
        EstimationStepModel(
          stepNumber: 4,
          title: 'Accept the quote',
          isCompleted: false,
        ),
        const EstimationStepModel(
          stepNumber: 5,
          title: 'Get your car serviced!',
        ),
      ],
    );
  }

  /// Factory for API response parsing
  factory EstimationModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('order_line') || json.containsKey('amount_total')) {
      return EstimationModel.fromOdooJson(json);
    }
    if (json.containsKey('notification_type') || json.containsKey('res_model')) {
      return EstimationModel.fromNotificationJson(json);
    }
    var stepsList = <EstimationStepModel>[];
    if (json['next_steps'] is List) {
      stepsList = (json['next_steps'] as List)
          .map((item) => EstimationStepModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      stepsList = EstimationModel.defaultStatic().nextSteps;
    }

    List<EstimationLineItemModel> lines = [];
    if (json['line_items'] is List) {
      lines = (json['line_items'] as List)
          .map((item) => EstimationLineItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return EstimationModel(
      id: json['id']?.toString() ?? 'EST-000',
      serviceName: json['service_name'] as String? ?? 'Interior Detailing',
      serviceDescription: json['service_description'] as String? ??
          'Estimated cost for your interior detailing service',
      estimatedAmount: (json['estimated_amount'] as num?)?.toDouble() ?? 2800.0,
      amountUntaxed: (json['amount_untaxed'] as num?)?.toDouble(),
      amountTax: (json['amount_tax'] as num?)?.toDouble(),
      currencySymbol: json['currency_symbol'] as String? ?? 'R',
      vehicleName: json['vehicle_name'] as String? ?? 'Volkswagen Polo TDI 2.0',
      vehicleType: json['vehicle_type'] as String? ?? 'Hatch Back',
      vehicleRegistration: json['vehicle_registration'] as String?,
      vehicleVin: json['vehicle_vin'] as String?,
      serviceDate: json['service_date'] as String? ?? '12th August',
      serviceTime: json['service_time'] as String? ?? '12:00 PM',
      validityDate: json['validity_date'] as String?,
      disclaimerText: json['disclaimer_text'] as String? ??
          'The above mentioned amount is the base price. We will share the final pricing after completing our inspection on 12th August at 12:00 PM.',
      state: json['state']?.toString() ?? 'sent',
      notificationType: json['notification_type']?.toString(),
      lineItems: lines,
      nextSteps: stepsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_name': serviceName,
      'service_description': serviceDescription,
      'estimated_amount': estimatedAmount,
      'amount_untaxed': amountUntaxed,
      'amount_tax': amountTax,
      'currency_symbol': currencySymbol,
      'vehicle_name': vehicleName,
      'vehicle_type': vehicleType,
      'vehicle_registration': vehicleRegistration,
      'vehicle_vin': vehicleVin,
      'service_date': serviceDate,
      'service_time': serviceTime,
      'validity_date': validityDate,
      'disclaimer_text': disclaimerText,
      'line_items': lineItems.map((item) => item.toJson()).toList(),
      'next_steps': nextSteps.map((step) => step.toJson()).toList(),
    };
  }

  String get formattedPrice {
    if (estimatedAmount % 1 == 0) {
      return '$currencySymbol ${estimatedAmount.toInt()}';
    }
    return '$currencySymbol ${estimatedAmount.toStringAsFixed(2)}';
  }

  static String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return 'August';
  }
}

