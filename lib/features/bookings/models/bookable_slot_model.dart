import 'package:timeless_detailing_customer_app/features/services/models/service_variant_model.dart';

class BookableSlot {
  final String datetime;
  final String startHour;
  final dynamic endHour;
  final bool isLongDuration;
  final double slotDuration;
  final String urlParameters;
  final List<AppointmentResource> availableResources;

  const BookableSlot({
    required this.datetime,
    required this.startHour,
    required this.endHour,
    required this.isLongDuration,
    required this.slotDuration,
    required this.urlParameters,
    required this.availableResources,
  });

  factory BookableSlot.fromJson(Map<String, dynamic> json) {
    List<AppointmentResource> resources = [];
    if (json['available_resources'] is List) {
      resources = (json['available_resources'] as List)
          .map((r) => AppointmentResource.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return BookableSlot(
      datetime: json['datetime']?.toString() ?? '',
      startHour: json['start_hour']?.toString() ?? '',
      endHour: json['end_hour'],
      isLongDuration: json['is_long_duration'] == true,
      slotDuration: (json['slot_duration'] as num?)?.toDouble() ?? 1.0,
      urlParameters: json['url_parameters']?.toString() ?? '',
      availableResources: resources,
    );
  }

  String get formattedTime {
    if (startHour.isNotEmpty) {
      final numVal = double.tryParse(startHour);
      if (numVal != null) {
        final hours = numVal.floor();
        final mins = ((numVal - hours) * 60).round();
        final period = hours >= 12 ? 'PM' : 'AM';
        final displayHour = hours > 12 ? hours - 12 : (hours == 0 ? 12 : hours);
        final displayMins = mins == 0 ? '00' : (mins < 10 ? '0$mins' : '$mins');
        return '$displayHour:$displayMins $period';
      }
      return startHour;
    }
    return datetime;
  }
}

class BookableSlotsResult {
  final String date;
  final String timezone;
  final int appointmentTypeId;
  final int resourceId;
  final List<BookableSlot> slots;

  const BookableSlotsResult({
    required this.date,
    required this.timezone,
    required this.appointmentTypeId,
    required this.resourceId,
    required this.slots,
  });

  factory BookableSlotsResult.fromJson(Map<String, dynamic> json) {
    List<BookableSlot> slotList = [];
    if (json['slots'] is List) {
      slotList = (json['slots'] as List)
          .map((s) => BookableSlot.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return BookableSlotsResult(
      date: json['date']?.toString() ?? '',
      timezone: json['timezone']?.toString() ?? '',
      appointmentTypeId: json['appointment_type_id'] is int
          ? json['appointment_type_id'] as int
          : int.tryParse(json['appointment_type_id']?.toString() ?? '0') ?? 0,
      resourceId: json['resource_id'] is int
          ? json['resource_id'] as int
          : int.tryParse(json['resource_id']?.toString() ?? '0') ?? 0,
      slots: slotList,
    );
  }
}
