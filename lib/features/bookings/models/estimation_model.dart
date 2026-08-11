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

  /// Factory for API response parsing (Odoo / REST API integration)
  factory EstimationModel.fromJson(Map<String, dynamic> json) {
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
