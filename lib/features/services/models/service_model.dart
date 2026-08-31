import 'package:timeless_detailing_customer_app/features/services/models/service_variant_model.dart';

class TimelessCoverageLine {
  final int id;
  final int sequence;
  final String? view;
  final String? viewImageUrl;
  final String? panelKey;
  final String title;
  final String? icon;
  final double xPercent;
  final double yPercent;
  final String? description;
  final int? productId;
  final String? productDisplayName;

  const TimelessCoverageLine({
    required this.id,
    required this.sequence,
    this.view,
    this.viewImageUrl,
    this.panelKey,
    required this.title,
    this.icon,
    this.xPercent = 0.0,
    this.yPercent = 0.0,
    this.description,
    this.productId,
    this.productDisplayName,
  });

  factory TimelessCoverageLine.fromJson(Map<String, dynamic> json) {
    int? pId;
    String? pName;
    if (json['product_id'] is Map) {
      pId = json['product_id']['id'] as int?;
      pName = json['product_id']['display_name']?.toString();
    } else if (json['product_id'] is List && (json['product_id'] as List).length >= 2) {
      pId = (json['product_id'] as List)[0] as int?;
      pName = (json['product_id'] as List)[1]?.toString();
    }

    return TimelessCoverageLine(
      id: json['id'] is int ? json['id'] as int : 0,
      sequence: json['sequence'] is int ? json['sequence'] as int : 0,
      view: json['view']?.toString(),
      viewImageUrl: json['view_image_url']?.toString(),
      panelKey: json['panel_key']?.toString(),
      title: json['title']?.toString() ?? '',
      icon: json['icon']?.toString(),
      xPercent: (json['x_percent'] as num?)?.toDouble() ?? 0.0,
      yPercent: (json['y_percent'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString(),
      productId: pId,
      productDisplayName: pName,
    );
  }
}

class DetailService {
  final String id;
  final String name;
  final String description;
  final double price;
  final double durationHours;
  final String imageUrl;
  final String category;
  final List<String> whatsIncluded;
  final int? odooProductId;
  final int? appointmentTypeId;
  final int? appointmentResourceId;
  final String? assetImagePath;
  final int? mobileCategoryId;
  final String? mobileCategoryName;
  final String? mobileImage;
  final List<TimelessCoverageLine> coverageLines;
  final List<ProductVariant> variants;

  const DetailService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationHours,
    required this.imageUrl,
    required this.category,
    required this.whatsIncluded,
    this.odooProductId,
    this.appointmentTypeId,
    this.appointmentResourceId,
    this.assetImagePath,
    this.mobileCategoryId,
    this.mobileCategoryName,
    this.mobileImage,
    this.coverageLines = const [],
    this.variants = const [],
  });

  DetailService copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? durationHours,
    String? imageUrl,
    String? category,
    List<String>? whatsIncluded,
    int? odooProductId,
    int? appointmentTypeId,
    int? appointmentResourceId,
    String? assetImagePath,
    int? mobileCategoryId,
    String? mobileCategoryName,
    String? mobileImage,
    List<TimelessCoverageLine>? coverageLines,
    List<ProductVariant>? variants,
  }) {
    return DetailService(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationHours: durationHours ?? this.durationHours,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      whatsIncluded: whatsIncluded ?? this.whatsIncluded,
      odooProductId: odooProductId ?? this.odooProductId,
      appointmentTypeId: appointmentTypeId ?? this.appointmentTypeId,
      appointmentResourceId: appointmentResourceId ?? this.appointmentResourceId,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      mobileCategoryId: mobileCategoryId ?? this.mobileCategoryId,
      mobileCategoryName: mobileCategoryName ?? this.mobileCategoryName,
      mobileImage: mobileImage ?? this.mobileImage,
      coverageLines: coverageLines ?? this.coverageLines,
      variants: variants ?? this.variants,
    );
  }

  factory DetailService.fromOdooJson(Map<String, dynamic> json) {
    List<String> parseIncluded(dynamic included) {
      if (included == null) return [];
      if (included is List) {
        return included.map((e) => e.toString()).toList();
      }
      if (included is String) {
        return included
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    }

    final rawPrice = json['list_price'] ?? json['lst_price'];
    final priceVal = (rawPrice is num) ? rawPrice.toDouble() : 0.0;
    final serviceName = json['name']?.toString() ?? 'Unknown Service';
    final lowerName = serviceName.toLowerCase();

    int? mobileCatId;
    String? mobileCatName;

    if (json['mobile_categ_id'] is Map) {
      final m = json['mobile_categ_id'] as Map;
      mobileCatId = m['id'] as int?;
      mobileCatName = m['name']?.toString();
    } else if (json['mobile_categ_id'] is List && (json['mobile_categ_id'] as List).isNotEmpty) {
      final list = json['mobile_categ_id'] as List;
      mobileCatId = list[0] is int ? list[0] as int : int.tryParse(list[0].toString());
      if (list.length > 1) mobileCatName = list[1].toString();
    }

    String derivedCategory = mobileCatName ??
        (json['categ_id'] is List
            ? (json['categ_id'] as List)[1].toString()
            : (json['categ_id']?.toString() ?? 'General'));

    String? assetImg;
    if (lowerName.contains('ppf') || lowerName.contains('protect')) {
      if (derivedCategory == 'General') derivedCategory = 'Protection';
      assetImg = 'assets/services/paint_care/paint_care.png';
    } else if (lowerName.contains('paint') ||
        lowerName.contains('correction') ||
        lowerName.contains('enhancement')) {
      if (derivedCategory == 'General') derivedCategory = 'Exterior';
      assetImg = 'assets/services/paint_care/paint_care.png';
    } else if (lowerName.contains('interior')) {
      if (derivedCategory == 'General') derivedCategory = 'Interior';
      assetImg = 'assets/services/interior/interior_detailing.png';
    }

    int? apptTypeId;
    if (json['appointment_type_id'] is Map) {
      final map = json['appointment_type_id'] as Map;
      apptTypeId = map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? '');
    } else if (json['appointment_type_id'] is List &&
        (json['appointment_type_id'] as List).isNotEmpty) {
      apptTypeId = (json['appointment_type_id'] as List)[0] is int
          ? (json['appointment_type_id'] as List)[0] as int
          : int.tryParse((json['appointment_type_id'] as List)[0]?.toString() ?? '');
    } else if (json['appointment_type_id'] is int) {
      apptTypeId = json['appointment_type_id'] as int;
    }

    int? apptResId;
    final rawRes = json['appointment_resource_id'] ?? json['appointment_resource_ids'];
    if (rawRes is Map) {
      apptResId = rawRes['id'] is int ? rawRes['id'] as int : int.tryParse(rawRes['id']?.toString() ?? '');
    } else if (rawRes is List && rawRes.isNotEmpty) {
      final first = rawRes[0];
      if (first is Map) {
        apptResId = first['id'] is int ? first['id'] as int : int.tryParse(first['id']?.toString() ?? '');
      } else {
        apptResId = first is int ? first : int.tryParse(first.toString());
      }
    } else if (rawRes is int) {
      apptResId = rawRes;
    }

    List<TimelessCoverageLine> parsedCoverage = [];
    if (json['timeless_coverage_line_ids'] is List) {
      parsedCoverage = (json['timeless_coverage_line_ids'] as List)
          .whereType<Map<String, dynamic>>()
          .map((c) => TimelessCoverageLine.fromJson(c))
          .toList();
    }

    List<ProductVariant> parsedVariants = [];
    if (json['product_variant_ids'] is List) {
      parsedVariants = (json['product_variant_ids'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => ProductVariant.fromJson(v))
          .toList();
    }

    if (parsedVariants.isNotEmpty) {
      apptTypeId ??= parsedVariants.first.appointmentType?.id;
      apptResId ??= parsedVariants.first.appointmentResource?.id;
    }

    final mobileImgStr = json['mobile_image'] is String ? json['mobile_image'] as String : null;

    return DetailService(
      id: json['id']?.toString() ?? json['id'].toString(),
      name: serviceName,
      description: json['description_sale']?.toString() ??
          json['description']?.toString() ??
          'Comprehensive professional detailing treatment for exceptional vehicle restoration and protection.',
      price: priceVal,
      durationHours: (json['detailing_duration'] as num?)?.toDouble() ??
          (json['appointment_duration'] as num?)?.toDouble() ??
          1.0,
      imageUrl: json['image_url']?.toString() ?? '',
      category: derivedCategory,
      whatsIncluded: parseIncluded(json['whats_included']),
      odooProductId: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      appointmentTypeId: apptTypeId,
      appointmentResourceId: apptResId,
      assetImagePath: assetImg,
      mobileCategoryId: mobileCatId,
      mobileCategoryName: mobileCatName,
      mobileImage: mobileImgStr,
      coverageLines: parsedCoverage,
      variants: parsedVariants,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'durationHours': durationHours,
      'imageUrl': imageUrl,
      'category': category,
      'whatsIncluded': whatsIncluded,
      'odooProductId': odooProductId,
      'assetImagePath': assetImagePath,
      'mobileCategoryId': mobileCategoryId,
      'mobileCategoryName': mobileCategoryName,
      'mobileImage': mobileImage,
    };
  }
}

