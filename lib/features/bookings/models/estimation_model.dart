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

class EstimationModel {
  final String id;
  final String serviceName;
  final String serviceDescription;
  final double estimatedAmount;
  final String currencySymbol;
  final String vehicleName;
  final String vehicleType;
  final String serviceDate;
  final String serviceTime;
  final String disclaimerText;
  final String state; // 'draft', 'sent', 'sale', 'cancel'
  final List<EstimationStepModel> nextSteps;

  const EstimationModel({
    required this.id,
    required this.serviceName,
    required this.serviceDescription,
    required this.estimatedAmount,
    required this.currencySymbol,
    required this.vehicleName,
    required this.vehicleType,
    required this.serviceDate,
    required this.serviceTime,
    required this.disclaimerText,
    this.state = 'sent',
    required this.nextSteps,
  });

  /// Static default estimation model matching Figma design prototype
  factory EstimationModel.defaultStatic() {
    return const EstimationModel(
      id: 'EST-28001',
      serviceName: 'Interior Detailing',
      serviceDescription: 'Estimated cost for your interior detailing service',
      estimatedAmount: 2800.0,
      currencySymbol: 'R',
      vehicleName: 'Volkswagen Polo TDI 2.0',
      vehicleType: 'Hatch Back',
      serviceDate: '12th August',
      serviceTime: '12:00 PM',
      disclaimerText:
          'The above mentioned amount is the base price. We will share the final pricing after completing our inspection on 12th August at 12:00 PM.',
      state: 'sent',
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
    final amountVal = (rawAmount is num) ? rawAmount.toDouble() : 2800.0;
    final orderState = json['state']?.toString() ?? 'sent';
    final nameStr = json['name']?.toString() ?? 'SO-001';

    String serviceNameStr = 'Vehicle Detailing Service';
    if (json['order_lines_detail'] is List && (json['order_lines_detail'] as List).isNotEmpty) {
      final firstLine = (json['order_lines_detail'] as List).first;
      if (firstLine is Map && firstLine['name'] != null) {
        serviceNameStr = firstLine['name'].toString();
      }
    }

    String vehicleNameStr = 'Client Vehicle';
    if (json['vehicle_make'] != null || json['vehicle_model'] != null) {
      final make = json['vehicle_make']?.toString() ?? '';
      final model = json['vehicle_model']?.toString() ?? '';
      vehicleNameStr = '$make $model'.trim();
    }

    String dateStr = 'Today';
    String timeStr = '12:00 PM';
    if (json['date_order'] != null) {
      final dt = DateTime.tryParse(json['date_order'].toString().replaceAll(' ', 'T'));
      if (dt != null) {
        final localDt = dt.add(const Duration(hours: 2));
        dateStr = '${localDt.day} ${_monthName(localDt.month)}';
        final hour = localDt.hour % 12 == 0 ? 12 : localDt.hour % 12;
        final amPm = localDt.hour >= 12 ? 'PM' : 'AM';
        final minStr = localDt.minute.toString().padLeft(2, '0');
        timeStr = '$hour:$minStr $amPm';
      }
    }

    return EstimationModel(
      id: nameStr,
      serviceName: serviceNameStr,
      serviceDescription: 'Final quotation sent by Timeless Detailing Technician',
      estimatedAmount: amountVal,
      currencySymbol: 'R',
      vehicleName: vehicleNameStr,
      vehicleType: 'Hatch Back',
      serviceDate: dateStr,
      serviceTime: timeStr,
      disclaimerText:
          'Please review the breakdown above and click Accept & Sign below to confirm your estimate.',
      state: orderState,
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

  /// Factory for API response parsing
  factory EstimationModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('order_line') || json.containsKey('amount_total')) {
      return EstimationModel.fromOdooJson(json);
    }
    var stepsList = <EstimationStepModel>[];
    if (json['next_steps'] is List) {
      stepsList = (json['next_steps'] as List)
          .map((item) => EstimationStepModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      stepsList = EstimationModel.defaultStatic().nextSteps;
    }

    return EstimationModel(
      id: json['id']?.toString() ?? 'EST-000',
      serviceName: json['service_name'] as String? ?? 'Interior Detailing',
      serviceDescription: json['service_description'] as String? ??
          'Estimated cost for your interior detailing service',
      estimatedAmount: (json['estimated_amount'] as num?)?.toDouble() ?? 2800.0,
      currencySymbol: json['currency_symbol'] as String? ?? 'R',
      vehicleName: json['vehicle_name'] as String? ?? 'Volkswagen Polo TDI 2.0',
      vehicleType: json['vehicle_type'] as String? ?? 'Hatch Back',
      serviceDate: json['service_date'] as String? ?? '12th August',
      serviceTime: json['service_time'] as String? ?? '12:00 PM',
      disclaimerText: json['disclaimer_text'] as String? ??
          'The above mentioned amount is the base price. We will share the final pricing after completing our inspection on 12th August at 12:00 PM.',
      state: json['state']?.toString() ?? 'sent',
      nextSteps: stepsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_name': serviceName,
      'service_description': serviceDescription,
      'estimated_amount': estimatedAmount,
      'currency_symbol': currencySymbol,
      'vehicle_name': vehicleName,
      'vehicle_type': vehicleType,
      'service_date': serviceDate,
      'service_time': serviceTime,
      'disclaimer_text': disclaimerText,
      'next_steps': nextSteps.map((step) => step.toJson()).toList(),
    };
  }

  String get formattedPrice {
    final amountInt = estimatedAmount.toInt();
    return '$currencySymbol $amountInt';
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
