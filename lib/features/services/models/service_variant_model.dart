class AppointmentResource {
  final int id;
  final String name;
  final int capacity;

  const AppointmentResource({
    required this.id,
    required this.name,
    required this.capacity,
  });

  factory AppointmentResource.fromJson(Map<String, dynamic> json) {
    return AppointmentResource(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      capacity: json['capacity'] is int ? json['capacity'] as int : int.tryParse(json['capacity']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'capacity': capacity,
  };
}

class AppointmentType {
  final int id;
  final String name;
  final int appointmentDuration; // duration in minutes
  final String messageIntro;
  final int minScheduleHours;
  final int maxScheduleDays;
  final int minCancellationHours;

  const AppointmentType({
    required this.id,
    required this.name,
    required this.appointmentDuration,
    required this.messageIntro,
    required this.minScheduleHours,
    required this.maxScheduleDays,
    required this.minCancellationHours,
  });

  factory AppointmentType.fromJson(Map<String, dynamic> json) {
    return AppointmentType(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      appointmentDuration: json['appointment_duration'] is int
          ? json['appointment_duration'] as int
          : (json['appointment_duration'] as num?)?.toInt() ?? 60,
      messageIntro: json['message_intro']?.toString() ?? '',
      minScheduleHours: json['min_schedule_hours'] is int
          ? json['min_schedule_hours'] as int
          : (json['min_schedule_hours'] as num?)?.toInt() ?? 24,
      maxScheduleDays: json['max_schedule_days'] is int
          ? json['max_schedule_days'] as int
          : (json['max_schedule_days'] as num?)?.toInt() ?? 30,
      minCancellationHours: json['min_cancellation_hours'] is int
          ? json['min_cancellation_hours'] as int
          : (json['min_cancellation_hours'] as num?)?.toInt() ?? 4,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'appointment_duration': appointmentDuration,
    'message_intro': messageIntro,
    'min_schedule_hours': minScheduleHours,
    'max_schedule_days': maxScheduleDays,
    'min_cancellation_hours': minCancellationHours,
  };
}

class ProductVariantValue {
  final int id;
  final String name;

  const ProductVariantValue({required this.id, required this.name});

  factory ProductVariantValue.fromJson(Map<String, dynamic> json) {
    return ProductVariantValue(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class ProductVariant {
  final int id;
  final String name;
  final String displayName;
  final double lstPrice;
  final List<ProductVariantValue> variantValues;
  final AppointmentType? appointmentType;
  final AppointmentResource? appointmentResource;
  final String? pageTagline;
  final String? pageIntro;
  final String? pageConclusion;
  final List<String> featureLines;

  const ProductVariant({
    required this.id,
    required this.name,
    required this.displayName,
    required this.lstPrice,
    required this.variantValues,
    this.appointmentType,
    this.appointmentResource,
    this.pageTagline,
    this.pageIntro,
    this.pageConclusion,
    this.featureLines = const [],
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    List<ProductVariantValue> values = [];
    if (json['product_template_variant_value_ids'] is List) {
      values = (json['product_template_variant_value_ids'] as List)
          .map((v) => ProductVariantValue.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    AppointmentType? apptType;
    if (json['appointment_type_id'] is Map<String, dynamic>) {
      apptType = AppointmentType.fromJson(json['appointment_type_id'] as Map<String, dynamic>);
    }

    AppointmentResource? apptResource;
    if (json['appointment_resource_id'] is Map<String, dynamic>) {
      apptResource = AppointmentResource.fromJson(json['appointment_resource_id'] as Map<String, dynamic>);
    }

    List<String> features = [];
    if (json['timeless_feature_line_ids'] is List) {
      for (final item in json['timeless_feature_line_ids']) {
        if (item is Map && item['text'] != null) {
          features.add(item['text'].toString());
        } else if (item is String) {
          features.add(item);
        }
      }
    }

    final tagline = (json['timeless_page_tagline'] != false && json['timeless_page_tagline'] != null)
        ? json['timeless_page_tagline'].toString()
        : null;

    final intro = (json['timeless_page_intro'] != false && json['timeless_page_intro'] != null)
        ? json['timeless_page_intro'].toString()
        : null;

    final conclusion = (json['timeless_page_conclusion'] != false && json['timeless_page_conclusion'] != null)
        ? json['timeless_page_conclusion'].toString()
        : null;

    return ProductVariant(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? json['name']?.toString() ?? '',
      lstPrice: (json['lst_price'] as num?)?.toDouble() ?? 0.0,
      variantValues: values,
      appointmentType: apptType,
      appointmentResource: apptResource,
      pageTagline: tagline,
      pageIntro: intro,
      pageConclusion: conclusion,
      featureLines: features,
    );
  }
}
